#!/usr/bin/env node

const tracer = require('dd-trace').init();
const { setTimeout } = require('timers/promises');

const oneMs = setTimeout.bind(null, 1);

async function nestedSpam () {
  return tracer.trace('nested-spam', {}, oneMs);
}

async function spam () {
  await tracer.trace('spam', { resource: 'spammer' }, nestedSpam);
}

process.on('exit', () => {
  console.log('Exiting Node.js spammer');
});

(async () => {
  console.log('Waiting 10 seconds for agent to be ready');
  await setTimeout(10000);

  console.log('Starting Node.js spammer.');

  while (true) {
    await spam();
  }
})();
