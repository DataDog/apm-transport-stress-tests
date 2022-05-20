namespace MockAgent
{
    public enum TestTransports
    {
        /// <summary>
        /// Default transport
        /// </summary>
        Tcp,

        /// <summary>
        /// Unix Domain Socket, primarily used in container orchestration
        /// </summary>
        Uds,

        /// <summary>
        /// Windows Named Pipes, primarily used in Azure App Service scenarios
        /// </summary>
        WindowsNamedPipe
    }
}
