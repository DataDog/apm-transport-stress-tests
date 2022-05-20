#pragma warning disable CS8604 // Possible null reference argument.
namespace MockAgent.HttpContent
{
    internal class BufferContent : IHttpContent
    {
        private readonly ArraySegment<byte> _buffer;

        public BufferContent(ArraySegment<byte> buffer)
        {
            _buffer = buffer;
        }

        public long? Length => _buffer.Count;

        public Task CopyToAsync(Stream destination)
        {
            return destination.WriteAsync(_buffer.Array, _buffer.Offset, _buffer.Count);
        }

        public Task CopyToAsync(byte[] buffer)
        {
            if (_buffer.Count > buffer.Length)
            {
                throw new ArgumentOutOfRangeException(
                    nameof(buffer),
                    $"Buffer of size {buffer.Length} is not large enough to hold content of size {_buffer.Count}");
            }

            Buffer.BlockCopy(
                src: _buffer.Array,
                srcOffset: _buffer.Offset,
                dst: buffer,
                dstOffset: 0,
                count: _buffer.Count);
            return Task.CompletedTask;
        }
    }
}
#pragma warning restore CS8604 // Possible null reference argument.
