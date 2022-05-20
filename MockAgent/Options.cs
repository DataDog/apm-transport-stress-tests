namespace MockAgent
{
    public class Options
    {
        internal const string DefaultTracesUnixDomainSocket = "/var/run/datadog/apm.socket";
        internal const string DefaultMetricsUnixDomainSocket = "/var/run/datadog/dsd.socket";

        public static readonly int DefaultPortTrace = 7126;
        public static readonly int DefaultPortStats = 7126;

        public bool UnixDomainSockets { get; set; } = true;

        public string TracesUnixDomainSocketPath { get; set; } = Environment.GetEnvironmentVariable("DD_APM_RECEIVER_SOCKET") ?? DefaultTracesUnixDomainSocket;

        public string MetricsUnixDomainSocketPath { get; set; } = Environment.GetEnvironmentVariable("DD_DOGSTATSD_SOCKET") ?? DefaultMetricsUnixDomainSocket;

        public bool Tcp { get; set; } = true;

        public int TracesPort { get; set; } = EnvironmentNumber("DD_TRACE_AGENT_PORT") ?? DefaultPortTrace;

        public int MetricsPort { get; set; } = EnvironmentNumber("DD_DOGSTATSD_PORT") ?? DefaultPortStats;

        private static int? EnvironmentNumber(string key)
        {
            var number = Environment.GetEnvironmentVariable(key);

            if (number == null) {
                return null;
            }

            return int.Parse(number);
        }
    }
}
