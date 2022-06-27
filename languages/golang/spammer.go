package main

import (
	"fmt"
	"time"

	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

func createTrace() {
	span := tracer.StartSpan("spam", tracer.ResourceName("spammer"))
	defer span.Finish()
	childSpan := tracer.StartSpan("nested-spam", tracer.ChildOf(span.Context()))
	time.Sleep(time.Millisecond)
	childSpan.Finish()
}

func main() {
	fmt.Printf("Waiting 10 seconds for agent to be ready\n")
	time.Sleep(10 * time.Second)
	fmt.Printf("Starting spammer at: %v\n", time.Now().Unix())
	tracer.Start()
	defer tracer.Stop()

	for {
		createTrace()
	}

	fmt.Printf("Finishing at: %v\n", time.Now().Unix())
}
