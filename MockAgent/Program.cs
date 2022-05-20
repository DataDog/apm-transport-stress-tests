using MockAgent;
using Newtonsoft.Json;
using System.Collections.Concurrent;

var tracesRecieved = new ConcurrentQueue<string>();
var statsReceived = new ConcurrentQueue<string>();

EventHandler<EventArgs<IList<IList<MockSpan>>>> displayTraces = (sender, args) =>
{
    var traces = args.Value;
    Console.WriteLine($"Traces received [{traces.Count}]");
    foreach (var trace in traces)
    {
        string json = JsonConvert.SerializeObject(traces, Formatting.Indented);
        tracesRecieved.Enqueue(json);
        File.WriteAllText($"/var/log/traces/traces_${DateTime.Now.Ticks}.json", json);
    }
};

EventHandler<EventArgs<string>> displayStats = (sender, args) =>
{
    Console.WriteLine(args.Value);
    statsReceived.Enqueue(args.Value);
    File.WriteAllText($"/var/log/stats/stats_${DateTime.Now.Ticks}.txt", args.Value);
};

var o = new Options();

DatadogAgent? tcpipAgent = null;
DatadogAgent? udsAgent = null;

try
{
    if (o.Tcp || args.Length == 0)
    {
        tcpipAgent = new DatadogAgent(port: o.TracesPort, useStatsd: true, requestedStatsDPort: o.MetricsPort);
        Console.WriteLine($"Listening for traces on TCP: {tcpipAgent.Port}");
        Console.WriteLine($"Listening for metrics on UDP port: {tcpipAgent.StatsdPort}");
        tcpipAgent.RequestDeserialized += displayTraces;
        tcpipAgent.MetricsReceived += displayStats;
    }

    if (o.UnixDomainSockets || args.Length == 0)
    {
        udsAgent = new DatadogAgent(new UnixDomainSocketConfig(o.TracesUnixDomainSocketPath, o.MetricsUnixDomainSocketPath));
        Console.WriteLine($"Listening for traces on Unix Domain Socket: {udsAgent.TracesUdsPath}");
        Console.WriteLine($"Listening for metrics on Unix Domain Socket: {udsAgent.StatsUdsPath}");
        udsAgent.RequestDeserialized += displayTraces;
        udsAgent.MetricsReceived += displayStats;
    }

    Console.WriteLine("Agent instances are bound.");

    File.WriteAllText($"/var/log/traces/able_to_write.txt", "");
    File.WriteAllText($"/var/log/stats/able_to_write.txt", "");

    Console.WriteLine("Finished output directory writes.");

    while (true)
    {
        Console.WriteLine($"Waiting... [{DateTime.Now.Ticks}]");
        await Task.Delay(1000);

        while (tracesRecieved.TryDequeue(out var trace))
            Console.WriteLine(trace);

        while (statsReceived.TryDequeue(out var stat))
            Console.WriteLine(stat);
    }
}
catch (Exception ex)
{
    Console.WriteLine(ex);
}
finally
{
    Console.WriteLine($"Disposing agents at {DateTime.Now.Ticks}");
    tcpipAgent?.Dispose();
    udsAgent?.Dispose();
    Console.WriteLine($"Exiting at {DateTime.Now.Ticks}");
}
