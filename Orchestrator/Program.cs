using Docker.DotNet;
using Docker.DotNet.Models;

Thread.Sleep(1000);

var start = DateTime.Now.Ticks;
Console.WriteLine($"Beginning orchestrator at {start}");

var cancellationToken = new CancellationTokenSource();

//DockerClient client = new DockerClientConfiguration().CreateClient();
DockerClient client = new DockerClientConfiguration(new Uri(@"unix:///var/run/docker.sock"),
                                                                null,
                                                                new TimeSpan(0, 0, 1000))
                                                                .CreateClient();

var containers = await client.Containers.ListContainersAsync(new ContainersListParameters { All = true });

ContainerListResponse agent;
ContainerListResponse? spammer = null;

foreach (var container in containers)
{
    Console.WriteLine($"Container - ID: {container.ID}, Names: {string.Join('|', container.Names)} ");

    if (container.Names.Contains("mockagent"))
    {
        agent = container;
    }

    if (container.Names.Contains("spammer"))
    {
        spammer = container;
    }
}

if (spammer == null)
{
    throw new Exception("Unable to find spammer container");
}

var timeout = EnvironmentNumber("TRANSPORT_STRESS_TIMEOUT_MS") ?? 20_000;

cancellationToken.CancelAfter(timeout);

//IProgress<ContainerStatsResponse> statsProgress =
//    new Progress<ContainerStatsResponse>(stats => { 
//        Console.WriteLine($"Stats: Read={stats.Read},PreRead={stats.PreRead},PidsStats={stats.PidsStats},BlkioStats={stats.BlkioStats},NumProcs={stats.NumProcs},StorageStats={stats.StorageStats},CPUStats={stats.CPUStats},PreCPUStats={stats.PreCPUStats},MemoryStats={stats.MemoryStats}"); 
//    });

while (!cancellationToken.Token.IsCancellationRequested)
{
    Thread.Sleep(50);
    //await client.Containers.GetContainerStatsAsync(
    //    spammer.ID,
    //    new ContainerStatsParameters
    //    {
    //    },
    //    statsProgress,
    //    cancellationToken.Token
    //    );
}

var end = DateTime.Now.Ticks;
Console.WriteLine($"Ending orchestrator at {end}, a total of {end - start} ticks.");

static int? EnvironmentNumber(string key)
{
    var number = Environment.GetEnvironmentVariable(key);

    if (number == null)
    {
        return null;
    }

    return int.Parse(number);
}