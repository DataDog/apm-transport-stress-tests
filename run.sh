#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

set -eu

# uds|tcpip
export TRANSPORT=${1:-uds}

OUTPUT_FOLDER=./shared/$TRANSPORT
LOGS_FOLDER=${OUTPUT_FOLDER}/logs-container/

if [[ "$TRANSPORT" == "uds" ]]; then
    export DD_APM_RECEIVER_SOCKET=/var/run/datadog/apm.socket
    export DD_DOGSTATSD_SOCKET=/var/run/datadog/dsd.socket
    # export DD_APM_RECEIVER_SOCKET=C:\Github\uds-stress-test-poc\shared\uds\uds-volume\apm.socket
    # export DD_DOGSTATSD_SOCKET=C:\Github\uds-stress-test-poc\shared\uds\uds-volume\dsd.socket
	echo Binding APM on ${DD_APM_RECEIVER_SOCKET} and DSD on ${DD_DOGSTATSD_SOCKET}
elif [[ "$TRANSPORT" == "tcpip" ]]; then
    export DD_TRACE_AGENT_PORT=7126
    export DD_DOGSTATSD_PORT=7125
	export DD_AGENT_HOST=127.0.0.1
	echo Binding TCP on port ${DD_TRACE_AGENT_PORT} and UDP on port ${DD_DOGSTATSD_PORT}
fi
	
# Clean logs/ folder
rm -rf $OUTPUT_FOLDER
mkdir -p $OUTPUT_FOLDER
mkdir -p $LOGS_FOLDER

echo ============ Run $TRANSPORT tests ===================
echo "ℹ️  Results and logs outputted to ${OUTPUT_FOLDER}"

docker inspect transport_tests/spammer > $LOGS_FOLDER/spammer_image.json
docker inspect transport_tests/orchestrator > $LOGS_FOLDER/orchestrator_image.json
docker inspect transport_tests/mockagent > $LOGS_FOLDER/mockagent_image.json

echo "Starting containers in background."
docker-compose up -d --force-recreate

export container_log_folder="unset"
# Save docker logs
for container in ${containers[@]}
do
    container_log_folder="${LOGS_FOLDER}/docker/${container}"
    docker-compose logs --no-color --no-log-prefix -f $container > $container_log_folder/stdout.log &

    # checking container, it should not be stopped here
    if [ -z `docker ps -q --no-trunc | grep $(docker-compose ps -q $container)` ]; then
        echo "ERROR: $container container is stopped. Here is the output:"
        docker-compose logs $container
        exit 1
    fi
done

echo "Outputting runner logs."

# Show output. Trick: The process will end when orchestrator ends
docker-compose logs -f orchestrator

# Not sure why docker compose down doesn't kill the spammer, so manually kill for now
docker kill spammer

# Getting orchestrator exit code.
EXIT_CODE=$(docker-compose ps -q orchestrator | xargs docker inspect -f '{{ .State.ExitCode }}')

# Stop all containers
docker-compose down --remove-orphans

# Exit with orchestrator's status
echo "Exiting with ${EXIT_CODE}"
exit $EXIT_CODE
