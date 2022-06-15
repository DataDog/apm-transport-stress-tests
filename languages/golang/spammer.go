package main

import (
	"fmt"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
	"time"
)

func makenestedspan() {
	span := tracer.StartSpan("nested-spam")
	defer span.Finish()
}

func makespan() {
	span := tracer.StartSpan("spam", tracer.ResourceName("spammer"))
	makenestedspan()
	defer span.Finish()
}

func main() {
	fmt.Printf("Waiting 10 seconds for agent ot be ready")
	time.Sleep(10)
	fmt.Printf("Starting spammer at: %v\n", time.Now().Unix())
	tracer.Start()

	for {
		makespan()
		time.Sleep(0.001)
	}

	fmt.Printf("Finishing at: %v\n", time.Now().Unix())
	defer tracer.Stop()
}
