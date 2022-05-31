#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

set -eu

# uds|tcpip
export TRANSPORT=${1:-uds}

# default 20k ms
export TIMEOUT=${2:-20000}

mkdir -p ./results
OUTPUT_FOLDER=./results/$TRANSPORT
LOGS_FOLDER=${OUTPUT_FOLDER}/logs

if [[ "$TRANSPORT" == "tcpip" ]]; then
    export DD_TRACE_AGENT_PORT=9126
    export DD_DOGSTATSD_PORT=9125

	OS_UNAME=$(uname -s)

	echo OS: $OS_UNAME
	
	if [[ "$OS_UNAME" = *"MINGW"* ]]; then
		export DD_AGENT_HOST=host.docker.internal
		echo Operating on a windows host with host.docker.internal
	else
		export DD_AGENT_HOST=localhost
		echo Operating on a non-windows host with localhost
	fi
	
	echo Binding TCP on port ${DD_TRACE_AGENT_PORT} and UDP on port ${DD_DOGSTATSD_PORT} against ${DD_AGENT_HOST}
elif [[ "$TRANSPORT" == "uds" ]]; then

    export DD_APM_RECEIVER_SOCKET=/var/run/datadog/apm.socket
    export DD_DOGSTATSD_SOCKET=/var/run/datadog/dsd.socket
    # export DD_APM_RECEIVER_SOCKET=C:\Github\uds-stress-test-poc\shared\uds\uds-volume\apm.socket
    # export DD_DOGSTATSD_SOCKET=C:\Github\uds-stress-test-poc\shared\uds\uds-volume\dsd.socket
	
	echo Binding APM on ${DD_APM_RECEIVER_SOCKET} and DSD on ${DD_DOGSTATSD_SOCKET}
	
	unset DD_AGENT_HOST
	unset DD_TRACE_AGENT_PORT
	unset DD_DOGSTATSD_PORT
fi
	
# Clean logs/ folder
rm -rf $OUTPUT_FOLDER
mkdir -p $OUTPUT_FOLDER
mkdir -p $LOGS_FOLDER

echo ============ Run $TRANSPORT tests ===================
echo "ℹ️  Results and logs outputted to ${OUTPUT_FOLDER}"

docker inspect transport-spammer > $OUTPUT_FOLDER/image_spammer.json
docker inspect transport-orchestrator > $OUTPUT_FOLDER/image_orchestrator.json
docker inspect transport-mockagent > $OUTPUT_FOLDER/image_mockagent.json

echo "Starting containers in background."
docker-compose up -d --force-recreate

export container_log_folder="unset"
containers=("mockagent" "orchestrator" "spammer")

# Save docker logs
for container in ${containers[@]}
do
    container_log_folder="${LOGS_FOLDER}/${container}"
	mkdir -p ${LOGS_FOLDER}/${container}
	echo Inspecting container logs ${container}, saving to ${container_log_folder}
    docker-compose logs --no-color --no-log-prefix -f $container > $container_log_folder/stdout.log &
done

# Show output. Trick: The process will end when orchestrator ends
docker-compose logs -f orchestrator

# Stop all containers
docker-compose down --remove-orphans

echo Forcing stop on all containers
# Not sure why docker compose down doesn't stop the spammer, so manually stop for now
docker stop spammer
docker stop mockagent
docker stop orchestrator
