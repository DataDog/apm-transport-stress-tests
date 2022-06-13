#!/usr/bin/env node

const tracer = require('dd-trace').init();

console.log('Waiting for ready.');
setTimeout(function() {
    // no-op
}, 10000);

console.log('Starting nodejs spammer.');

var traceCount = 0;

var maxRuns = 100000000;

var sendLots = function() {
    tracer.trace('spam', { resource: 'spammer' }, () => {
		setTimeout(function() {	
            tracer.trace('nested-spam', {}, () => {})
		}, 1);
    })
	
	traceCount++;
	
	if (traceCount % 1000 == 0) {
		console.log('Another 1000 traces sent.')
	}	
	
	if (--maxRuns <= 0) {
		console.log('Exceeded maximum runs.');
		return false;
	}
	
	setTimeout(function() {	
        sendLots();
	}, 1);
};

sendLots();

console.log('Exiting nodejs spammer');
