#!/bin/bash

set -eu

sed -i -e '/gem .ddtrace./d' Gemfile
if [ -e "/binaries/dd-trace-rb" ]; then
    echo "Install from folder /binaries/dd-trace-rb"
    echo "gem 'ddtrace', require: 'ddtrace/auto_instrument', path: '/binaries/dd-trace-rb'" >> Gemfile
elif [ $(ls /binaries/ruby-load-from-bundle-add | wc -l) = 0 ]; then
    echo "Install prod version"
    echo "gem 'ddtrace', '~> 1.0.0.beta1', require: 'ddtrace/auto_instrument'" >> Gemfile
else
    options=$(cat /binaries/ruby-load-from-bundle-add)
    echo "Install from $options"
    echo $options >> Gemfile
fi

bundle update ddtrace

bundle list | grep ddtrace > SYSTEM_TESTS_LIBRARY_VERSION
bundle list | grep libddwaf > SYSTEM_TESTS_LIBDDWAF_VERSION || true
