<?php

declare(ticks=1);

namespace App;

use DataDog\DogStatsd;

require __DIR__ . '/vendor/autoload.php';

\pcntl_signal(
    SIGINT,
    function ($signal) {
        if ($signal === SIGINT) {
            echo "Existing due to SIGINT\n";
            exit(0);
        } else {
            echo "Handling signal $signal\n";
        }
    }
);

$statsd = new DogStatsd(
    array(
        'host' => 'observer',
        'port' => 8125,
        'global_tags' => [
            'env' => \getenv('DD_ENV'),
            'service' => \getenv('DD_SERVICE'),
            'version' => \getenv('DD_VERSION'),
        ],
    )
);

function root_function(DogStatsd $statsd)
{
    $statsd->increment('transport_sample.span_created');
    nested_function($statsd);
}

function nested_function(DogStatsd $statsd)
{
    $statsd->increment('transport_sample.span_created');
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

while (1) {
    root_function($statsd);
    echo "Done\n";
}
