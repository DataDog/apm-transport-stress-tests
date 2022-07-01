import os
import time

from datadog import initialize, statsd
from ddtrace import config, tracer

initialize(
    statsd_host="observer",
    statsd_port=8125,
    statsd_constant_tags=["{}:{}".format(k, v) for k, v in config.tags.items()],
    statsd_constant_tags=[
        "language:python",
        "transport:{}".format(os.environ["TRANSPORT"]),
        "conc:{}".format(os.environ["CONCURRENT_SPAMMERS"]),
        "trunid:{}".format(os.environ["TRANSPORT_RUN_ID"]),
        "env:{}".format(os.environ["DD_ENV"]),
        "service:{}".format(os.environ["DD_SERVICE"]),
        "version:{}".format(os.environ["DD_VERSION"]),
    ],
)


print("Starting spammer")
spans_created = 0

while True:
    try:
        with tracer.trace("spam", resource="spammer"):
            spans_created += 1
            statsd.increment("transport_sample.span_created")

            with tracer.trace("nested-spam"):
                spans_created += 1
                statsd.increment("transport_sample.span_created")

                time.sleep(0.001)  # Sleep for 1 milliseconds
    except KeyboardInterrupt:
        print("SIGINT caught, exiting")
        break


print("Reached limit, exiting")
print("Created {} spans".format(spans_created))
