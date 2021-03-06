namespace MockAgent.HttpContent
{
    internal class StreamContent : IHttpContent
    {
        public StreamContent(Stream stream, long? length)
        {
            Stream = stream;
            Length = length;
        }

        public Stream Stream { get; }

        public long? Length { get; }

        public Task CopyToAsync(Stream destination)
        {
            return Stream.CopyToAsync(destination);
        }

        public async Task CopyToAsync(byte[] buffer)
        {
            if (!Length.HasValue)
            {
                ThrowHelper.ThrowInvalidOperationException("Unable to CopyToAsync with buffer when content Length is unknown");
            }

            if (Length > buffer.Length)
            {
                ThrowHelper.ThrowArgumentException($"Provided buffer was smaller {buffer.Length} than the content length {Length}");
            }

            var length = 0;
            long remaining = Length.Value;
            while (true)
            {
                var bytesToRead = (int)Math.Min(remaining, int.MaxValue);
                var bytesRead = await Stream.ReadAsync(buffer, offset: length, count: bytesToRead).ConfigureAwait(false);

                length += bytesRead;
                remaining -= bytesRead;

                if (bytesRead == 0 || remaining <= 0)
                {
                    return;
                }
            }
        }
    }
}
