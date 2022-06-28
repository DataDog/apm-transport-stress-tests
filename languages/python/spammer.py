import time

from datadog import initialize, statsd
from ddtrace import tracer

options = {
    "statsd_host": "observer",
    "statsd_port": 8125,
}

initialize(**options)


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