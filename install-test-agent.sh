# Install the test agent

if [ -f "./dd-apm-test-agent/setup.py" ]; then
    echo "Installing test agent from sub-repository."
    pip install ./dd-apm-test-agent
else
    echo "Installing test agent from latest github commit."
    # pip install git+https://github.com/Datadog/dd-apm-test-agent
	pip install git+https://github.com/Datadog/dd-apm-test-agent@delay
fi
