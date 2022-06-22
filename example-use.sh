#!/bin/bash

# Unless explicitly stated otherwise all files in this repository are licensed under the the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2021 Datadog, Inc.

set -eu

# DD_API_KEY must be available for the realagent
# export DD_API_KEY=$YOUR_API_KEY

export AGENT_DOCKERFILE=realagent #realagent|mockagent|dotnetagent
export TRACER=dotnet #dotnet|java|python|golang|nodejs|ruby

# Associates the two separate runs
export RUN_ID=$(date +%s)

# These variables have defaults, but you may choose to override the settings
# export TRANSPORT_STRESS_TIMEOUT_MS=60000
# export CONCURRENT_SPAMMERS=10

git clone --depth 1 https://github.com/DataDog/apm-transport-stress-tests.git
./build.sh $TRACER $AGENT_DOCKERFILE
./run.sh tcpip
./run.sh uds
