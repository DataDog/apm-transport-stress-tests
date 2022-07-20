# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

#!/bin/bash

set -e

# dotnet|nodejs|python|ruby|golang|java|php|cpp
LANGUAGE=${1}

# mockagent|realagent
AGENT_TYPE=${2}

export ALTERNATIVE_LOAD_NEEDED=false
export EXTRA_SPAMMER_TAG="concurrent-spammer"

for highoverhead in nodejs
do
    if [[ "$LANGUAGE" == "$highoverhead" ]]; then
        echo "Using the alternative load generator in the ./languages/load directory."
        export EXTRA_SPAMMER_TAG="not-for-load"
        export ALTERNATIVE_LOAD_NEEDED=true
        break
    fi
done

echo "Using indicator tag for sample: ${EXTRA_SPAMMER_TAG}"

echo =============== Building Agent ===============

AGENT_DOCKERFILE=./${AGENT_TYPE}.Dockerfile
docker build --progress=plain -f ${AGENT_DOCKERFILE} -t transport-mockagent .
	
echo =============== Building Spammer ===============

SPAMMER_DOCKERFILE=./languages/${LANGUAGE}/Dockerfile

docker build \
    --progress=plain \
    -f ${SPAMMER_DOCKERFILE} \
    -t transport-spammer \
    -t ${EXTRA_SPAMMER_TAG} \
    ./languages/${LANGUAGE}
	

if [[ "$ALTERNATIVE_LOAD_NEEDED" == "true" ]]; then

    echo =============== Building Alternative Concurrent Spammer ===============

    docker build \
        --progress=plain \
        -f ./languages/load/Dockerfile \
        -t concurrent-spammer \
        ./languages/load

fi
