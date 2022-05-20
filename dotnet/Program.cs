Console.WriteLine("Spamming traces");
Console.WriteLine();

while (true)
{
    using (var s1 = Datadog.Trace.Tracer.Instance.StartActive("spam"))
    {
        Console.Write(".");

        using (var s2 = Datadog.Trace.Tracer.Instance.StartActive("nested-spam"))
        {
            Thread.Sleep(1);
        }
    }
}
