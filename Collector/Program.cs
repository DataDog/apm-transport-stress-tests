var start = DateTime.Now.Ticks;
Console.WriteLine($"Beginning collector at {start}");

// Scrub stats and send

var end = DateTime.Now.Ticks;
Console.WriteLine($"Ending orchestrator at {end}, a total of {end - start} ticks.");
