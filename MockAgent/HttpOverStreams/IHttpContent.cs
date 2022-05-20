namespace MockAgent
{
    internal interface IHttpContent
    {
        long? Length { get; }

        Task CopyToAsync(Stream destination);

        Task CopyToAsync(byte[] buffer);
    }
}
