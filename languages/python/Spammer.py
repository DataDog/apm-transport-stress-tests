import ddtrace
import time
from ddtrace import tracer

print("Starting spammer")

@tracer.wrap("nested-spam", service="my-sandwich-making-svc")
def nested_spam():
    time.sleep(0.001)   # Sleep for 1 milliseconds
    return

@tracer.wrap("spam", resource="spammer")
def spam():
    nested_spam()
    return

while True:
    spam()

print("Reached limit, exiting")
