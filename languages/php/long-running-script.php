<?php

declare(ticks=1);

namespace App;

use DataDog\DogStatsd;

require __DIR__ . '/vendor/autoload.php';

$sigint_received = 0;
$spans_created = 0;
$spans_created_previous_track = 0;

$statsd = new DogStatsd(
    array(
        'host' => 'observer',
        'port' => 8125,
        'global_tags' => [
            'language' => 'php',
            'env' => \getenv('DD_ENV'),
            'service' => \getenv('DD_SERVICE'),
            'version' => \getenv('DD_VERSION'),
            'conc' => \getenv('CONCURRENT_SPAMMERS'),
            'transport' => \getenv('TRANSPORT'),
            'trunid' => \getenv('TRANSPORT_RUN_ID'),
        ],
    )
);

\pcntl_signal(
    SIGINT,
    function ($signal) {
        if ($signal === SIGINT) {
            $GLOBALS["sigint_received"] = 1;
            echo "SIGINT received\n";
        } else {
            echo "Handling signal $signal\n";
        }
    }
);

function root_function(DogStatsd $statsd)
{
    nested_function($statsd);
    $GLOBALS["spans_created"] = $GLOBALS["spans_created"] + 2;
    $period_span_diff = $GLOBALS["spans_created"] - $GLOBALS["spans_created_previous_track"];
    if ($period_span_diff > 199) {
        echo "Incrementing span count by $period_span_diff \n";
        $statsd->increment('transport_sample.spans_created', 1.0, null, $period_span_diff);
        $GLOBALS["spans_created_previous_track"] = $GLOBALS["spans_created"];
    }
}

function nested_function(DogStatsd $statsd)
{
    // Sleep 1 ms
    \usleep(1000);
}

\DDTrace\trace_function(
    'App\root_function',
    function ($span) {
        $span->name = 'span';
        $span->resource = 'spammer';
    }
);

\DDTrace\trace_function(
    'App\nested_function',
    function ($span) {
        $span->name = 'span';
        $span->resource = 'spammer';
    }
);

// Waiting for observer to be able to receive metrics, until this will be implemented in `./run.sh` or via health-checks
\sleep(10);

$statsd->increment('transport_sample.run');

while ($GLOBALS["sigint_received"] != 1) {
    root_function($statsd);
}

$period_span_diff = $GLOBALS["spans_created"] - $GLOBALS["spans_created_previous_track"];
echo "Incrementing span count by $period_span_diff \n";
$statsd->increment('transport_sample.span_created', 1.0, null, $period_span_diff);

echo "Total span count $spans_created\n";
echo "Exiting due to SIGINT\n";
$statsd->increment('transport_sample.end');
echo "Incremented end metric\n";
$statsd->increment('transport_sample.span_logged', 1.0, null, $spans_created);
echo "Incremented span count metric\n";

echo "Waiting 5s for metrics to flush \n";
sleep(5);

echo "Finished flushing metrics\n";

exit(0);
