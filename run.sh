#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

set -eu

# uds|tcpip
export TRANSPORT=${1:-uds}
export TRANSPORT_STRESS_TIMEOUT_MS=${2:-60000}
export DD_TEST_STALL_REQUEST_SECONDS=${3:-5}

export DD_TRACE_DEBUG="0"
export DD_LOG_LEVEL="debug"
export DD_ENV="transport-tests"
export DD_VERSION="main"

mkdir -p ./results
OUTPUT_FOLDER=./results/$TRANSPORT
LOGS_FOLDER=${OUTPUT_FOLDER}/logs

OS_UNAME=$(uname -s)

echo OS: $OS_UNAME
	
if [[ "$TRANSPORT" == "tcpip" ]]; then
    export DD_TRACE_AGENT_PORT=9126
    export DD_APM_RECEIVER_PORT=9126
    export DD_DOGSTATSD_PORT=9125
	export DD_SERVICE="tcp"

	if [[ "$OS_UNAME" = *"MINGW"* ]]; then
		export DD_AGENT_HOST=host.docker.internal
		echo Operating on a windows host with host.docker.internal
	else
		export DD_AGENT_HOST=127.0.0.1
		echo Operating on a non-windows host with localhost
	fi
	
	echo Binding TCP on port ${DD_TRACE_AGENT_PORT} and UDP on port ${DD_DOGSTATSD_PORT} against ${DD_AGENT_HOST}
elif [[ "$TRANSPORT" == "uds" ]]; then

	if [[ "$OS_UNAME" = *"MINGW"* ]]; then
		echo UDS is not supported on Windows yet
		exit 1
	fi

	export DD_SERVICE="uds"	
    export DD_APM_RECEIVER_SOCKET=/var/run/datadog/apm.socket
    export DD_DOGSTATSD_SOCKET=/var/run/datadog/dsd.socket
	
	echo Binding APM on ${DD_APM_RECEIVER_SOCKET} and DSD on ${DD_DOGSTATSD_SOCKET}
	
	unset DD_AGENT_HOST
	unset DD_TRACE_AGENT_PORT
	unset DD_APM_RECEIVER_PORT
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

echo "Cleaning any stale ready signals"
rm -f ./tmp/signals/ready.txt

echo "Starting containers in background"
docker-compose up -d

echo "Waiting to signal spammer"
sleep 5
mkdir -p ./tmp
mkdir -p ./tmp/signals
echo "Ready, set, go!" > ./tmp/signals/ready.txt
docker cp ./tmp/signals/. transport-spammer:/app

export container_log_folder="unset"
containers=("mockagent" "spammer" "observer")

# Save docker logs
for container in ${containers[@]}
do
    container_log="${LOGS_FOLDER}/${container}-stdout.log"
	echo Inspecting container logs ${container}, saving to ${container_log}
    docker-compose logs --no-color --no-log-prefix -f $container > $container_log &
done

# docker inspect transport-spammer
export SPAMMER_CONTAINER_ID=$(docker inspect --format="{{.Id}}" transport-spammer)

echo "Spammer container ID is ${SPAMMER_CONTAINER_ID}"

echo "Starting observer"
# ./observe.sh start

echo Sleeping for $TRANSPORT_STRESS_TIMEOUT_MS milliseconds
sleep $((TRANSPORT_STRESS_TIMEOUT_MS/1000))

echo "Stopping observer"
# ./observe.sh stop

echo "Stopping all containers"
docker-compose down --remove-orphans
