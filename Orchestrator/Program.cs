
var start = DateTime.Now.Ticks;
Console.WriteLine($"Beginning orchestrator at {start}");

var cancellationToken = new CancellationTokenSource();

var timeout = EnvironmentNumber("TRANSPORT_STRESS_TIMEOUT_MS") ?? 20_000;

Task.Run(async () =>
{
    await Task.Delay(timeout);
    cancellationToken.Cancel();
});

while (!cancellationToken.IsCancellationRequested)
{
    Thread.Sleep(10);
}

var end = DateTime.Now.Ticks;
Console.WriteLine($"Beginning orchestrator at {end}, a total of {end - start} ticks.");

static int? EnvironmentNumber(string key)
{
    var number = Environment.GetEnvironmentVariable(key);

    if (number == null)
    {
        return null;
    }

    return int.Parse(number);
}