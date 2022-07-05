import os
import time

from datadog import initialize, statsd
from ddtrace import config, tracer

initialize(
    statsd_host="observer",
    statsd_port=8125,
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
last_created = 0

statsd.increment("transport_sample.run")

while True:
    try:
        with tracer.trace("spam", resource="spammer"):
            spans_created += 1

            with tracer.trace("nested-spam"):
                spans_created += 1

                time.sleep(0.001)  # Sleep for 1 milliseconds

        # Only increment the count every 200 spans (100 traces, ~1 per second) to reduce the load on dogstatsd
        diff = spans_created - last_created
        if diff > 200:
            statsd.increment("transport_sample.span_created", diff)
            last_created = spans_created
    except KeyboardInterrupt:
        # Make sure to send a final count of spans created
        diff = spans_created - last_created
        if diff:
            statsd.increment("transport_sample.span_created", diff)

        print("SIGINT caught, exiting")
        break


statsd.increment("transport_sample.end")
statsd.increment("transport_sample.span_logged", spans_created)
print("Reached limit, exiting")
print("Created {} spans".format(spans_created))
