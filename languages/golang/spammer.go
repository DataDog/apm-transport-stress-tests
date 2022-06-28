package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"time"

	"github.com/DataDog/datadog-go/statsd"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

func main() {
	fmt.Printf("Waiting 10 seconds for agent to be ready\n")
	time.Sleep(10 * time.Second)
	fmt.Printf("Starting spammer at: %v\n", time.Now().Unix())
	tracer.Start()
	defer tracer.Stop()
	statsdClient, err := statsd.New("observer:8125")
	if err != nil {
		log.Fatal(err)
	}
	stressTest := &stressTest{statsdClient}

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, os.Interrupt)
	for {
		select {
		case <-sigs:
			fmt.Printf("Finishing at: %v\n", time.Now().Unix())
			statsdClient.Close()
			os.Exit(0)
		default:
			stressTest.createTrace()
		}
	}
}

type stressTest struct {
	statsdClient *statsd.Client
}

// createTrace creates a trace with two spans,
// where "nested-spam" is a child of "spam".
// Each span creation sends an event to DogStatsD to
// help with throughput analysis.
func (st *stressTest) createTrace() {
	st.statsdClient.Incr("transport_sample.span_created", nil, 1)
	span := tracer.StartSpan("spam", tracer.ResourceName("spammer"))
	defer span.Finish()

	st.statsdClient.Incr("transport_sample.span_created", nil, 1)
	childSpan := tracer.StartSpan("nested-spam", tracer.ChildOf(span.Context()))
	time.Sleep(time.Millisecond)
	childSpan.Finish()
}
