
var start = DateTime.Now.Ticks;
Console.WriteLine($"Beginning orchestrator at {start}");

var cancellationToken = new CancellationTokenSource();

Task.Run(async () =>
{
    await Task.Delay(20_000);
    cancellationToken.Cancel();
});

while (!cancellationToken.IsCancellationRequested)
{
    Thread.Sleep(10);
}

var end = DateTime.Now.Ticks;
Console.WriteLine($"Beginning orchestrator at {end}, a total of {end - start} ticks.");
