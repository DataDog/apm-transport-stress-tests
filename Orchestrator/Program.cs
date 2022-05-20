// See https://aka.ms/new-console-template for more information
Console.WriteLine("Hello, World!");

var cancellationToken = new CancellationTokenSource();

Task.Run(async () =>
{
    await Task.Delay(10_000);
    cancellationToken.Cancel();
});

while (!cancellationToken.IsCancellationRequested)
{
    Thread.Sleep(10);
}
