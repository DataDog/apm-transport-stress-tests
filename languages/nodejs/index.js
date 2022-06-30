#!/usr/bin/env node

const StatsD = require('hot-shots');
const tracer = require('dd-trace');
const { setTimeout } = require('timers/promises');

const sleepArr = new Int32Array(new SharedArrayBuffer(4))
function sleep (ms) {
  Atomics.wait(sleepArr, 0, 0, ms)
}
const log = process._rawDebug

let alive = true;

const oneMs = setTimeout.bind(null, 1);
const client = new StatsD({
  host: 'observer',
  port: 8125,
  globalTags: { env: process.env.NODE_ENV },
  bufferFlushInterval: 20, // Default of 1 second piles up too much data
  errorHandler:  () => { /* ignore errors for now */ }
});

function nestedSpam () {
  return tracer.trace('nested-spam', {}, () => sleep(1000));
}

function spam () {
  tracer.trace('spam', { resource: 'spammer' }, nestedSpam);
}

process.on('SIGINT', () => {
  alive = false;
});

log('Waiting 10 seconds for agent to be ready');
sleep(10000);
tracer.init();

log('Starting Node.js spammer.');

function loop () {
  if (alive) {
    spam();
    client.increment('transport_sample.span_created', 2);
    setImmediate(loop);
  } else {
    log('Received SIGINT. Exiting cleanly.');
    client.close((error) => {
      if (error) log('Error closing StatsD', error)
      log('Exiting Node.js spammer');
    });
  }
}
loop();
