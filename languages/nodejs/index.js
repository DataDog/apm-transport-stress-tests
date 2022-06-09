#!/usr/bin/env node

const tracer = require('dd-trace').init();

console.log('Waiting for ready.');
setTimeout(function() {
    // no-op
}, 10000);

console.log('Starting nodejs spammer.');

var traceCount = 0;

var maxRuns = 10000000;

while (true) {
    tracer.trace('spam', { resource: 'spammer' }, () => {
        tracer.trace('nested-spam', {}, () => {
              setTimeout(function() {
				  // no-op
				}, 1);
        })
    })
	
	traceCount++;
	
	if (traceCount % 100 == 0) {
		console.log('Another 100 traces sent.')
	}
	
	if (--maxRuns <= 0) {
		console.log('Exceeded maximum runs.');
		break;
	}
}

console.log('Exiting nodejs spammer');
