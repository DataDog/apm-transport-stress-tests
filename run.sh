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
export TRANSPORT_RUN_ID=${TRANSPORT_RUN_ID:=DEFAULT}

echo "Run id is set to ${TRANSPORT_RUN_ID}"

if [[ "${TRANSPORT_RUN_ID}" == "DEFAULT" ]]; then
    export TRANSPORT_RUN_ID=$(date +%s)
fi

if [[ "${CONCURRENT_SPAMMERS}" == "DEFAULT" ]]; then
    export CONCURRENT_SPAMMERS=10
fi

if [[ "$TRACER" == "nodejs" ]]; then
    echo "This language has experiences exit code 137 with too much in the tags."
    TAG_LENGTH=300
    TAG_COUNT=100
else
    TAG_LENGTH=1000
    TAG_COUNT=100
fi

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


echo "Running for profile: TRANSPORT_RUN_ID ${TRANSPORT_RUN_ID}, tracer $TRACER, transport ${TRANSPORT}, timeout ${TRANSPORT_STRESS_TIMEOUT_MS}, concurrency ${CONCURRENT_SPAMMERS}"

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

    echo Binding APM on ${DD_APM_RECEIVER_SOCKET}

    unset DD_AGENT_HOST
    unset DD_HOSTNAME
    unset DD_TRACE_AGENT_PORT
    unset DD_APM_RECEIVER_PORT
    unset DD_DOGSTATSD_PORT

else
    echo "Unknown protocol. Please use \"uds\" or \"tcpip\""
    exit 1
fi

# Clean logs/ folder
rm -rf $OUTPUT_FOLDER
mkdir -p $OUTPUT_FOLDER
mkdir -p $LOGS_FOLDER

export HOST_POSTFIX=${TRANSPORT_RUN_ID}-${TRACER}-${TRANSPORT}-conc${CONCURRENT_SPAMMERS}

echo ============ Run $TRANSPORT tests ===================
echo "ℹ️  Results and logs outputted to ${OUTPUT_FOLDER}"

docker inspect transport-spammer > $OUTPUT_FOLDER/image_spammer.json
docker inspect transport-mockagent > $OUTPUT_FOLDER/image_mockagent.json

export TRANSPORT_STRESS_RUN_TAG="conc${CONCURRENT_SPAMMERS}_run${TRANSPORT_RUN_ID}"
export SHARED_TAGS="conc:${CONCURRENT_SPAMMERS} trunid:${TRANSPORT_RUN_ID} env:${DD_ENV} service:${DD_SERVICE} version:${DD_VERSION} language:${TRACER}"
export DD_TAGS="${SHARED_TAGS}"

echo "Sending DD_TAGS $DD_TAGS"

# We need to start the mockagent ahead of time for this language
echo "Starting agent and observer before sample."
docker-compose up -d mockagent
docker-compose up -d observer
echo "Waiting for setup."
sleep 5

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

containers=$(docker ps | awk '{if(NR>1) print $NF}')

# loop through all containers
for container in $containers
do
    if [[ $container == *"spammer"* ]]; then    
        echo ================================    
        echo "Sending SIGINT to container: $container"
        # Signal for graceful exit if the sample supports it
        docker kill --signal SIGINT $container
    fi
done

echo ================================

echo "Wait 20 seconds for shutdown handling and stats flushing"
sleep 20

echo "Displaying containers"
docker ps

# SPAMMER_EXIT_CODE=$(docker ps -a | grep transport-spammer)
EXIT_CODE=$(docker-compose ps -q spammer | xargs docker inspect -f '{{ .State.ExitCode }}')

echo "Stopping all containers"
export DOCKER_CLIENT_TIMEOUT=120
export COMPOSE_HTTP_TIMEOUT=120
docker-compose down --remove-orphans

echo "Spammer exited with $EXIT_CODE, test will fail on non-zero."

for unimplemented in java
do
    if [[ "$TRACER" == "$unimplemented" ]]; then
        echo "This language has not yet implemented graceful SIGINT"
        exit 0
    fi
done

# This language has implemented SIGINT
exit $EXIT_CODE
