#!/usr/bin/env node
const tracer = require('dd-trace').init();

while (true) {
    tracer.trace('spam', { resource: 'spammer' }, () => {
        tracer.trace('nested-spam', {}, () => {
              // no-op
        })
    })
}
