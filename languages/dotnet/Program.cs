
Console.WriteLine($"Waiting for ready at {DateTime.Now.Ticks}.");

Thread.Sleep(10000);

Console.WriteLine($"Starting at {DateTime.Now.Ticks}.");

while (true)
{
    using (var s1 = Datadog.Trace.Tracer.Instance.StartActive("spam"))
    {
        using (var s2 = Datadog.Trace.Tracer.Instance.StartActive("nested-spam"))
        {
            // no-op
            Thread.Sleep(1);
        }
    }
}
