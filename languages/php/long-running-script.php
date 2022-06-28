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
    )
);

function root_function(DogStatsd $statsd)
{
    $statsd->increment('transport_sample.span_created');
    nested_function();
}

function nested_function()
{
    // Sleep 1 ms
    \usleep(1000);
    echo "Done\n";
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
}
