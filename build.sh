# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

#!/bin/bash

set -e

# dotnet|nodejs|python|ruby|golang|java|php|cpp
LANGUAGE=${1}

# mockagent|realagent
AGENT_TYPE=${2}

echo =============== Building Agent ===============

AGENT_DOCKERFILE=./${AGENT_TYPE}.Dockerfile
docker build --progress=plain -f ${AGENT_DOCKERFILE} -t transport-mockagent .

echo =============== Building Orchestrator ===============

docker build --progress=plain -f ./Orchestrator/Dockerfile -t transport-orchestrator ./Orchestrator
	
echo =============== Building Spammer ===============

SPAMMER_DOCKERFILE=./languages/${LANGUAGE}/Dockerfile

docker build \
    --progress=plain \
    -f ${SPAMMER_DOCKERFILE} \
    -t transport-spammer \
    ./languages/${LANGUAGE}
