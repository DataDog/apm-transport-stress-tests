
using StatsdClient;

Console.WriteLine($"Waiting for ready at {DateTime.Now.Ticks}.");

Thread.Sleep(10000);

Console.WriteLine($"Starting at {DateTime.Now.Ticks}.");

var dogstatsdConfig = new StatsdConfig
{
    StatsdServerName = "observer",
    StatsdPort = 8125,
    ConstantTags = new [] { 
        "language:dotnet",
        $"env:{Environment.GetEnvironmentVariable("DD_ENV")}",
        $"service:{Environment.GetEnvironmentVariable("DD_SERVICE")}",
        $"version:{Environment.GetEnvironmentVariable("DD_VERSION")}",
        $"conc:{Environment.GetEnvironmentVariable("CONCURRENT_SPAMMERS")}",
        $"trunid:{Environment.GetEnvironmentVariable("TRANSPORT_RUN_ID")}",
        $"transport:{Environment.GetEnvironmentVariable("TRANSPORT")}",
    },
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

int allSpans = 0;

using (var dogStatsdService = new DogStatsdService())
{
    dogStatsdService.Configure(dogstatsdConfig);

    dogStatsdService.Increment("transport_sample.run", value: 1);

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

        allSpans += 2;
        
        dogStatsdService.Increment("transport_sample.span_created", value: 2);
    }


    dogStatsdService.Increment("transport_sample.span_logged", value: allSpans);
    dogStatsdService.Increment("transport_sample.end", value: 1);
    dogStatsdService.Flush();
}

Console.WriteLine($"Total spans created: {allSpans}");
Console.WriteLine("Executing finalizer code.");
