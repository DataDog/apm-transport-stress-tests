#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

set -eu

# uds|tcpip
export TRANSPORT=${1:-uds}

export TRANSPORT_STRESS_TIMEOUT_MS=${TRANSPORT_STRESS_TIMEOUT_MS:=60000}
export DD_TEST_STALL_REQUEST_SECONDS=${DD_TEST_STALL_REQUEST_SECONDS:=4}
export CONCURRENT_SPAMMERS=${CONCURRENT_SPAMMERS:=DEFAULT}
export TRACER=${TRACER:=unknown}
export RUN_ID=${RUN_ID:=unset}

echo "Run id is set to ${RUN_ID}"

if [[ "${CONCURRENT_SPAMMERS}" == "DEFAULT" ]]; then
    export RUN_ID=$(date +%s)
fi

if [[ "${CONCURRENT_SPAMMERS}" == "DEFAULT" ]]; then
    export CONCURRENT_SPAMMERS=10
fi

TAG_LENGTH=1000
TAG_COUNT=100

GLOBAL_TAGS_FILLER=""
TAG_VALUE=""

for ((i=TAG_LENGTH; i>=1; i--))
do
	TAG_VALUE+="A"
done

echo "Using global tags filler [$TAG_COUNT] with a value length of ${TAG_LENGTH}"

for ((i=TAG_COUNT; i>=1; i--))
do
    GLOBAL_TAGS_FILLER+="tag${i}:${TAG_VALUE}, "
done

GLOBAL_TAGS_FILLER=${GLOBAL_TAGS_FILLER::-2}

export DD_TRACE_GLOBAL_TAGS=$GLOBAL_TAGS_FILLER


echo "Running for profile: run_id ${RUN_ID}, tracer $TRACER, transport ${TRANSPORT}, timeout ${TRANSPORT_STRESS_TIMEOUT_MS}, concurrency ${CONCURRENT_SPAMMERS}"

if [[ "${DEBUG_MODE:='false'}" == "true" ]]; then
    export DD_TRACE_DEBUG="1"
    export DD_LOG_LEVEL="debug"
	echo "DEBUG MODE IS ENABLED"
else
    export DD_TRACE_DEBUG="0"
    export DD_LOG_LEVEL="info"
fi

export RUNNER=${GITHUB_REF:=$HOSTNAME}
export DD_ENV="transport-tests-${RUNNER}"

echo "Using env of ${DD_ENV}"

mkdir -p ./results
OUTPUT_FOLDER=./results/$TRANSPORT
LOGS_FOLDER=${OUTPUT_FOLDER}/logs

OS_UNAME=$(uname -s)

echo OS: $OS_UNAME

export DD_TAGS="transport_stress_run_id:conc${CONCURRENT_SPAMMERS}_run${RUN_ID}"

echo "Sending DD_TAGS $DD_TAGS"

if [[ "$TRANSPORT" == "tcpip" ]]; then
    export DD_TRACE_AGENT_PORT=6126
    export DD_APM_RECEIVER_PORT=6126
    export DD_DOGSTATSD_PORT=6125
	export DD_SERVICE="${TRACER}"
	export DD_VERSION="tcpip"

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
		echo "UDS is not supported on Windows yet"
		exit 1
	fi

	export DD_SERVICE="${TRACER}"
	export DD_VERSION="uds"
	export DD_APM_RECEIVER_SOCKET=/var/run/datadog/apm.socket
	# export DD_DOGSTATSD_SOCKET=/var/run/datadog/dsd.socket

	echo Binding APM on ${DD_APM_RECEIVER_SOCKET} # and DSD on ${DD_DOGSTATSD_SOCKET}

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

for noracestart in ruby
do
	if [[ "$TRACER" == "$noracestart" ]]; then
	    # We need to start the mockagent ahead of time for this language
        docker-compose up -d mockagent
		echo "[LANGUAGE-EXCEPTION] This language fails with a race condition looking for the socket in UDS"
		sleep 5
		break
	fi
done

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

echo Sleeping for $TRANSPORT_STRESS_TIMEOUT_MS milliseconds
sleep $((TRANSPORT_STRESS_TIMEOUT_MS/1000))

# Signal for graceful exit if the sample supports it
docker kill --signal SIGINT transport-spammer

echo "Wait 5 seconds for shutdown handling"
sleep 5

# SPAMMER_EXIT_CODE=$(docker ps -a | grep transport-spammer)
EXIT_CODE=$(docker-compose ps -q spammer | xargs docker inspect -f '{{ .State.ExitCode }}')

echo "Stopping all containers"
export DOCKER_CLIENT_TIMEOUT=120
export COMPOSE_HTTP_TIMEOUT=120
docker-compose down --remove-orphans

echo "Spammer exited with $EXIT_CODE, test will fail on non-zero."

for unimplemented in golang nodejs java
do
	if [[ "$TRACER" == "$unimplemented" ]]; then
		echo "This language has not yet implemented graceful SIGINT"
		exit 0
	fi
done

# This language has implemented SIGINT
exit $EXIT_CODE
