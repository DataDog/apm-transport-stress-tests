package main

import (
	"fmt"
	"time"

	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

func makenestedspan() {
	span := tracer.StartSpan("nested-spam")
	time.Sleep(1 * time.Millisecond)
	defer span.Finish()
}

func makespan() {
	span := tracer.StartSpan("spam", tracer.ResourceName("spammer"))
	makenestedspan()
	defer span.Finish()
}

func main() {
	fmt.Printf("Waiting 10 seconds for agent to be ready\n")
	time.Sleep(10 * time.Second)
	fmt.Printf("Starting spammer at: %v\n", time.Now().Unix())
	tracer.Start()

	for {
		makespan()
	}

	fmt.Printf("Finishing at: %v\n", time.Now().Unix())
	defer tracer.Stop()
}
