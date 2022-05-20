using System.Text;

namespace MockAgent
{
    internal class MockHttpParser
    {
        private const string ContentLengthHeaderKey = "Content-Length";

        public static async Task<MockHttpRequest> ReadRequest(Stream stream)
        {
            var headers = new HttpHeaders();
            char currentChar = char.MinValue;
            int streamPosition = 0;

            // https://tools.ietf.org/html/rfc2616#section-4.2
            const int bufferSize = 10;

            var stringBuilder = new StringBuilder();

            var chArray = new byte[bufferSize];

            async Task GoNextChar()
            {
                var bytesRead = await stream.ReadAsync(chArray, offset: 0, count: 1).ConfigureAwait(false);
                if (bytesRead == 0)
                {
                    throw new InvalidOperationException($"Unexpected end of stream at position {streamPosition}");
                }

                currentChar = Encoding.ASCII.GetChars(chArray)[0];
                streamPosition++;
            }

            async Task ReadUntil(StringBuilder builder, char stopChar)
            {
                while (!currentChar.Equals(stopChar))
                {
                    builder.Append(currentChar);
                    await GoNextChar().ConfigureAwait(false);
                }
            }

            async Task ReadUntilNewLine(StringBuilder builder)
            {
                do
                {
                    if (await IsNewLine().ConfigureAwait(false))
                    {
                        break;
                    }

                    await ReadUntil(builder, DatadogHttpValues.CarriageReturn).ConfigureAwait(false);
                }
                while (true);
            }

            async Task<bool> IsNewLine()
            {
                if (currentChar.Equals(DatadogHttpValues.CarriageReturn))
                {
                    // end of headers
                    // Next character should be a LineFeed, regardless of Linux/Windows
                    // Skip the newline indicator
                    await GoNextChar().ConfigureAwait(false);

                    if (!currentChar.Equals(DatadogHttpValues.LineFeed))
                    {
                        throw new Exception($"Unexpected character {currentChar} in headers: CR must be followed by LF");
                    }

                    return true;
                }

                return false;
            }

            stringBuilder.Clear();

            // Read headers
            do
            {
                await GoNextChar().ConfigureAwait(false);

                // Check for end of headers
                if (await IsNewLine().ConfigureAwait(false))
                {
                    // Empty line, content starts next
                    break;
                }

                // Read key
                await ReadUntil(stringBuilder, stopChar: ':').ConfigureAwait(false);

                var name = stringBuilder.ToString().Trim();
                stringBuilder.Clear();

                // skip separator
                await GoNextChar().ConfigureAwait(false);

                // Read value
                await ReadUntilNewLine(stringBuilder).ConfigureAwait(false);

                var value = stringBuilder.ToString().Trim();
                stringBuilder.Clear();

                headers.Add(name, value);
            }
            while (true);

            var length = long.TryParse(headers.GetValue(ContentLengthHeaderKey), out var headerValue) ? headerValue : (long?)null;

#pragma warning disable CS8629 // Nullable value type may be null.
            return new MockHttpRequest()
            {
                Headers = headers,
                ContentLength = length.Value,
                Body = new HttpContent.StreamContent(stream, length)
            };
#pragma warning restore CS8629 // Nullable value type may be null.
        }

        internal class MockHttpRequest
        {
            public HttpHeaders Headers { get; set; } = new HttpHeaders();

            public long ContentLength { get; set; }

            public HttpContent.StreamContent? Body { get; set; }
        }
    }
}
