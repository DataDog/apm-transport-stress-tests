#!/usr/bin/env node

const tracer = require('dd-trace').init();
const { setTimeout } = require('timers/promises');
const StatsD = require('hot-shots');

let alive = true;

const oneMs = setTimeout.bind(null, 1);
const client = new StatsD({
  host: 'observer',
  port: 8125,
  globalTags: { env: process.env.NODE_END },
  bufferFlushInterval: 20, // Default of 1 second piles up too much data
  errorHandler: function (error) {
    console.log('Socket errors caught here:', error);
  }
});

async function nestedSpam () {
  return tracer.trace('nested-spam', {}, oneMs);
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

  console.log('Starting Node.js spammer.');

  while (alive) {
    await spam();
    client.increment('transport_sample.span_created', 2);
  }

  console.log('Received SIGINT. Exiting cleanly.');
  client.close(function (error) {
    console.log('Error closing StatsD', error)
  });
  console.log('Exiting Node.js spammer');
})();
