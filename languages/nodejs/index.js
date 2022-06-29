#!/usr/bin/env node

const StatsD = require('hot-shots');
const tracer = require('dd-trace');
const { setTimeout } = require('timers/promises');

let alive = true;

const oneMs = setTimeout.bind(null, 1);
const client = new StatsD({
  host: 'observer',
  port: 8125,
  globalTags: { env: process.env.NODE_ENV },
  bufferFlushInterval: 20, // Default of 1 second piles up too much data
  errorHandler:  () => { /* ignore errors for now */ }
});

async function nestedSpam () {
  return await tracer.trace('nested-spam', {}, oneMs);
}

async function spam () {
  await tracer.trace('spam', { resource: 'spammer' }, nestedSpam);
}

process.on('SIGINT', () => {
  alive = false;
});

(async () => {
  console.log('Waiting 10 seconds for agent to be ready');
  await setTimeout(10000);
  tracer.init();

  console.log('Starting Node.js spammer.');

  while (alive) {
    await spam();
    client.increment('transport_sample.span_created', 2);
  }

  console.log('Received SIGINT. Exiting cleanly.');
  client.close((error) => {
    if (error) console.log('Error closing StatsD', error)
    console.log('Exiting Node.js spammer');
  });
})();
