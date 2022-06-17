#!/usr/bin/env node

const tracer = require('dd-trace').init();

console.log('Waiting for ready.');
setTimeout(function() {
    // no-op
}, 10000);

console.log('Starting nodejs spammer.');

var spam = function() {
    tracer.trace('spam', { resource: 'spammer' }, () => {
		setTimeout(function() {	
            tracer.trace('nested-spam', {}, () => {})
		}, 1);
    })
};

while (true) {
	setTimeout(function() {	
        spam();
	}, 1);
}

console.log('Exiting nodejs spammer');
