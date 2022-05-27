# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

#!/bin/bash

set -e

# dotnet|nodejs|python|ruby|golang|java|php|cpp
LANGUAGE=${1:-dotnet}

echo =============== Building Mock Agent ===============

docker build --progress=plain -f ./mockagent.Dockerfile -t transport_tests/mockagent .
exit 0

echo =============== Building Orchestrator ===============

docker build --progress=plain -f ./Orchestrator/Dockerfile -t transport_tests/orchestrator ./Orchestrator
	
echo =============== Building Spammer ===============

DOCKERFILE=./${LANGUAGE}/Dockerfile

docker build \
    --progress=plain \
    -f ${DOCKERFILE} \
    -t transport_tests/spammer \
    ./${LANGUAGE}
