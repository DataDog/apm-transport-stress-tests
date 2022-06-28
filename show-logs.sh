#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

set -eu

TRANSPORT=${1:-unknown}
LANGUAGE=${2:-unknown}
CONTAINER=${3:-unknown}

OUTPUT_FOLDER=./results/$TRANSPORT
LOGS_FOLDER=${OUTPUT_FOLDER}/logs
	
container_log="${LOGS_FOLDER}/${CONTAINER}-stdout.log"
cat $container_log

if [[ "$LANGUAGE" == "dotnet" ]]; then
    if [[ "$CONTAINER" == "spammer" ]]; then
        echo "=================== Exporting extra log file for dotnet ==================="
        tracer_log_folder="${LOGS_FOLDER}/tracer/dotnet"
        for file in $tracer_log_folder/*.log; do echo $file; cat $file; echo; done
    fi
fi
