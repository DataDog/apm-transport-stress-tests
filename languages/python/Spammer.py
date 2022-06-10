import ddtrace
import time

print("Starting spammer")

F = 100000000

while True or limit <= 0:
    ddtrace.tracer.trace('span').finish()
    time.sleep(0.001)
    limit =- 1

print("Reached limit, exiting")
