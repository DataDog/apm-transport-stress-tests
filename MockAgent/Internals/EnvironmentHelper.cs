namespace MockAgent
{
    public class EnvironmentHelper
    {
        public TestTransports TransportType { get; set; } = TestTransports.Tcp;

        public DatadogAgent GetMockAgent(bool useStatsD = false, int? fixedPort = null)
        {
            DatadogAgent? agent = null;

            // Decide between transports
            if (TransportType == TestTransports.Uds)
            {
                var tracesUdsPath = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
                var metricsUdsPath = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
                agent = new DatadogAgent(new UnixDomainSocketConfig(tracesUdsPath, metricsUdsPath) { UseDogstatsD = useStatsD });
            }
            else if (TransportType == TestTransports.WindowsNamedPipe)
            {
                agent = new DatadogAgent(new WindowsPipesConfig($"trace-{Guid.NewGuid()}", $"metrics-{Guid.NewGuid()}") { UseDogstatsD = useStatsD });
            }
            else
            {
                // Default
                var agentPort = fixedPort ?? TcpPortProvider.GetOpenPort();
                agent = new DatadogAgent(agentPort, useStatsd: useStatsD);
            }

            return agent;
        }
    }
}
