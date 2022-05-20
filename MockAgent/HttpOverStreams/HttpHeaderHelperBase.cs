namespace MockAgent
{
    internal abstract class HttpHeaderHelperBase
    {
        protected abstract string MetadataHeaders { get; }

        protected abstract string ContentType { get; }

        public Task WriteLeadingHeaders(HttpRequest request, TextWriter writer)
        {
            var leadingHeaders =
                $"{request.Verb} {request.Path} HTTP/1.1{DatadogHttpValues.CrLf}Host: {request.Host}{DatadogHttpValues.CrLf}Accept-Encoding: identity{DatadogHttpValues.CrLf}Content-Length: {request.Content.Length ?? 0}{DatadogHttpValues.CrLf}{MetadataHeaders}";
            return writer.WriteAsync(leadingHeaders);
        }

        public Task WriteHeader(TextWriter writer, HttpHeaders.HttpHeader header)
        {
            return writer.WriteAsync($"{header.Name}: {header.Value}{DatadogHttpValues.CrLf}");
        }
    }
}
