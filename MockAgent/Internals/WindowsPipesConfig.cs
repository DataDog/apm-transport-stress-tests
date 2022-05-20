namespace MockAgent
{
    public class WindowsPipesConfig
    {
        public WindowsPipesConfig(string traces, string metrics)
        {
            Traces = traces;
            Metrics = metrics;
        }

        public string Traces { get; }

        public string Metrics { get; }

        public bool UseDogstatsD { get; set; } = false;
    }
}
