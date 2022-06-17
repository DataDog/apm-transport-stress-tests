#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

set -eu

# uds|tcpip
export TRANSPORT=${1:-uds}

export TRANSPORT_STRESS_TIMEOUT_MS=${TRANSPORT_STRESS_TIMEOUT_MS:=120000}
export DD_TEST_STALL_REQUEST_SECONDS=${DD_TEST_STALL_REQUEST_SECONDS:=4}
export CONCURRENT_SPAMMERS=${CONCURRENT_SPAMMERS:=0}
export TRACER=${TRACER:=unknown}
export RUN_ID=$(date +%s)

echo "Running for profile: run_id ${RUN_ID}, tracer $TRACER, transport ${TRANSPORT}, timeout ${TRANSPORT_STRESS_TIMEOUT_MS}, concurrency ${CONCURRENT_SPAMMERS}"

if [[ "${DEBUG_MODE:='false'}" == "true" ]]; then
    export DD_TRACE_DEBUG="1"
    export DD_LOG_LEVEL="debug"
else
    export DD_TRACE_DEBUG="0"
    export DD_LOG_LEVEL="info"
fi

export DD_ENV="transport-tests"
export DD_VERSION="main"

mkdir -p ./results
OUTPUT_FOLDER=./results/$TRANSPORT
LOGS_FOLDER=${OUTPUT_FOLDER}/logs

OS_UNAME=$(uname -s)

echo OS: $OS_UNAME
	
if [[ "$TRANSPORT" == "tcpip" ]]; then
    export DD_TRACE_AGENT_PORT=6126
    export DD_APM_RECEIVER_PORT=6126
    export DD_DOGSTATSD_PORT=6125
	export DD_SERVICE="tcpip"
	export DD_TAGS="run_id:${RUN_ID},transport:tcpip,tracer:${TRACER}"

	if [[ "$OS_UNAME" = *"MINGW"* ]]; then
		export DD_AGENT_HOST=host.docker.internal
		export DD_HOSTNAME=host.docker.internal
		echo Operating on a windows host with host.docker.internal
	else
		#export DD_AGENT_HOST=127.0.0.1
		export DD_AGENT_HOST=mockagent
		export DD_HOSTNAME=mockagent
		echo Operating on a non-windows host with localhost
	fi
	
	echo Binding TCP on port ${DD_TRACE_AGENT_PORT} and UDP on port ${DD_DOGSTATSD_PORT} against ${DD_AGENT_HOST}
elif [[ "$TRANSPORT" == "uds" ]]; then

	if [[ "$OS_UNAME" = *"MINGW"* ]]; then
		echo UDS is not supported on Windows yet
		exit 1
	fi

	export DD_SERVICE="uds"	
	export DD_TAGS="run_id:${RUN_ID},transport:uds,tracer:${TRACER}"
    export DD_APM_RECEIVER_SOCKET=/var/run/datadog/apm.socket
    export DD_DOGSTATSD_SOCKET=/var/run/datadog/dsd.socket
	
	echo Binding APM on ${DD_APM_RECEIVER_SOCKET} and DSD on ${DD_DOGSTATSD_SOCKET}
	
	unset DD_AGENT_HOST
	unset DD_HOSTNAME
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
docker inspect transport-mockagent > $OUTPUT_FOLDER/image_mockagent.json

echo "Starting containers in background with spammer concurrency ${CONCURRENT_SPAMMERS}"
docker-compose up -d --scale concurrent-spammer=${CONCURRENT_SPAMMERS}

echo "Displaying containers"
docker ps

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

# echo "Starting observer"
# ./observe.sh start

echo Sleeping for $TRANSPORT_STRESS_TIMEOUT_MS milliseconds
sleep $((TRANSPORT_STRESS_TIMEOUT_MS/1000))

# echo "Stopping observer"
# ./observe.sh stop

echo "Stopping all containers"
docker-compose down --remove-orphans
