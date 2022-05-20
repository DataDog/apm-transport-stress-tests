#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

set -eu

# set .env if exists. Allow users to keep their conf via env vars
if test -f ".env"; then
    source .env
fi

LOGS_FOLDER=./shared/$TRANSPORT/logs/

# Clean logs/ folder
rm -rf $LOGS_FOLDER
mkdir -p $LOGS_FOLDER

echo ============ Run $TRANSPORT tests ===================
echo "ℹ️  Log folder is ./${LOGS_FOLDER}"

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

# Getting orchestrator exit code.
EXIT_CODE=$(docker-compose ps -q orchestrator | xargs docker inspect -f '{{ .State.ExitCode }}')

# Stop all containers
docker-compose down --remove-orphans

# Exit with orchestrator's status
echo "Exiting with ${EXIT_CODE}"
exit $EXIT_CODE
