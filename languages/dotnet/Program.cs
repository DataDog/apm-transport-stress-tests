
using StatsdClient;

Console.WriteLine($"Waiting for ready at {DateTime.Now.Ticks}.");

Thread.Sleep(10000);

Console.WriteLine($"Starting at {DateTime.Now.Ticks}.");

var dogstatsdConfig = new StatsdConfig
{
    StatsdServerName = "observer",
    StatsdPort = 8125,
    ConstantTags = new [] { "language:dotnet" },
};

var tcs = new TaskCompletionSource();
var sigintReceived = false;

Console.CancelKeyPress += (_, ea) =>
{
    // Tell .NET to not terminate the process
    ea.Cancel = true;

    Console.WriteLine("Received SIGINT (Ctrl+C), this is good.");
    tcs.SetResult();
    sigintReceived = true;
    Environment.ExitCode = 0;
};

AppDomain.CurrentDomain.ProcessExit += (_, _) =>
{
    if (!sigintReceived)
    {
        Console.WriteLine("Received SIGTERM, for forced exit, this is bad.");
        tcs.SetResult();
    }
    else
    {
        Console.WriteLine("Received SIGTERM, ignoring it because already processed SIGINT");
    }
};

using (var dogStatsdService = new DogStatsdService())
{
    dogStatsdService.Configure(dogstatsdConfig);
    while (!tcs.Task.IsCompleted)
    {
        using (var s1 = Datadog.Trace.Tracer.Instance.StartActive("spam"))
        {
            s1.Span.ResourceName = "spammer";
            using (var s2 = Datadog.Trace.Tracer.Instance.StartActive("nested-spam"))
            {
                // no-op
                Thread.Sleep(1);
            }
        }
        
        dogStatsdService.Increment("transport_sample.span_created", value: 2);
    }

    dogStatsdService.Flush();
}

Console.WriteLine("Executing finalizer code.");
