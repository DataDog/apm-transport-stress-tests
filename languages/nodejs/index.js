#!/usr/bin/env node

const StatsD = require('hot-shots');
const tracer = require('dd-trace');

const log = process._rawDebug

let alive = true;
var metadata = {
  span_count: 0,
  previous_submit_span_count: 0
};

var tracer_version = require('dd-trace/package.json').version;
log("Using tracer version " + tracer_version);

const client = new StatsD({
  host: 'observer',
  port: 8125,
  globalTags: { 
    env: process.env.DD_ENV,
    service: process.env.DD_SERVICE,
    version: process.env.DD_VERSION,
    trunid: process.env.TRANSPORT_RUN_ID,
    conc: process.env.CONCURRENT_SPAMMERS,
    transport: process.env.TRANSPORT,
    tracer_version: tracer_version,
    language: "nodejs"
  },
  bufferFlushInterval: 20, // Default of 1 second piles up too much data
  errorHandler:  () => { /* ignore errors for now */ }
});

function nestedSpam (childOf, cb) {
  const span = tracer.startSpan('nested-spam', { childOf })

  setTimeout(() => {
    span.finish()
    cb()
  }, 1)
}

function spam (cb) {
  const span = tracer.startSpan('spam', {
    tags: {
      'resource.name': 'spammer'
    }
  })

  nestedSpam(span, () => {
    span.finish()
    cb()
  })
}

process.on('SIGINT', () => {
  alive = false;

  log('Total spans sent: ' + metadata.span_count);
  client.increment('transport_sample.span_created', metadata.span_count - metadata.previous_submit_span_count);
  client.increment('transport_sample.span_logged', metadata.span_count);
  client.increment('transport_sample.end', 1);

  client.close((error) => {
    if (error) log('Error closing StatsD', error)
    log('Exiting Node.js spammer');
  });

  log('Exiting cleanly.');
});

function loop () {
  if (alive) {
    spam(() => {
      metadata.span_count += 2;
      var diff = metadata.span_count - metadata.previous_submit_span_count;
      if (diff > 499) {
        client.increment('transport_sample.span_created', diff);
        metadata.previous_submit_span_count = metadata.span_count;
        log('Total spans: ' + metadata.span_count);
      }
      setImmediate(loop);
    });
  } else {
    log('Received SIGINT.');
  }
}

log('Waiting 10 seconds for agent to be ready');
setTimeout(() => {
  client.increment('transport_sample.run', 1);
  tracer.init();

  log('Starting Node.js spammer.');
  loop();

}, 10000);
