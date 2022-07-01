#!/usr/bin/env node

const StatsD = require('hot-shots');
const tracer = require('dd-trace');

const log = process._rawDebug

let alive = true;

const client = new StatsD({
  host: 'observer',
  port: 8125,
  globalTags: { env: process.env.NODE_ENV },
  bufferFlushInterval: 20, // Default of 1 second piles up too much data
  errorHandler:  () => { /* ignore errors for now */ }
});

function nestedSpam (cb) {
  return tracer.trace('nested-spam', {}, (_, done) => {
    setTimeout(done, 1);
    done();
    cb();
  });
}

function spam (cb) {
  tracer.trace('spam', { resource: 'spammer' }, (_, done) => {
    nestedSpam(() => {
      done();
      cb();
    })
  });
}

process.on('SIGINT', () => {
  alive = false;
});

function loop () {
  if (alive) {
    spam(() => {
      client.increment('transport_sample.span_created', 2);
      setImmediate(loop);
    });
  } else {
    log('Received SIGINT. Exiting cleanly.');
    client.close((error) => {
      if (error) log('Error closing StatsD', error)
      log('Exiting Node.js spammer');
    });
  }
}

log('Waiting 10 seconds for agent to be ready');
setTimeout(() => {
  tracer.init();
  log('Starting Node.js spammer.');
  loop();
}, 10000);

