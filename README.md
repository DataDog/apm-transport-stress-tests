# APM Transport Stress Tests

Stress and chaos testing the tracer transports.

Running this suite for your language:

```
export DD_API_KEY=$YOUR_API_KEY

export AGENT_DOCKERFILE=realagent #realagent|mockagent|dotnetagent
export TRACER=$dotnet #dotnet|java|python|golang|nodejs|ruby

export RUN_ID=$(date +%s)

# Adjust these variables as needed for your scenarios
export TRANSPORT_STRESS_TIMEOUT_MS=DEFAULT # Can set to something explicit like 120000
export CONCURRENT_SPAMMERS=DEFAULT # Can set to something specific like 10

git clone --depth 1 https://github.com/DataDog/apm-transport-stress-tests.git
./build.sh $TRACER $AGENT_DOCKERFILE
./run.sh tcpip
./run.sh uds
# Save or inspect ./results directory for logs
# Inspect metrics sent to your organization tagged with transport-tests-${BRANCH || HOSTNAME}
```
