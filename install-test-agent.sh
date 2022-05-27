# Install the test agent

if [ -d "dd-apm-test-agent" ]; then
    echo "Installing test agent from sub-repository."
    pip install ./dd-apm-test-agent
else
    echo "Installing test agent from latest github commit."
    pip install git+https://github.com/Datadog/dd-apm-test-agent
fi
