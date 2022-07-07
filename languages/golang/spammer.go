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
	globalTags := []string{
		"language:golang",
		fmt.Sprintf("transport:%s", os.Getenv("TRANSPORT")),
		fmt.Sprintf("conc:%s", os.Getenv("CONCURRENT_SPAMMERS")),
		fmt.Sprintf("trunid:%s", os.Getenv("TRANSPORT_RUN_ID")),
		fmt.Sprintf("env:%s", os.Getenv("DD_ENV")),
		fmt.Sprintf("service:%s", os.Getenv("DD_SERVICE")),
		fmt.Sprintf("version:%s", os.Getenv("DD_VERSION")),
	}
	statsdClient, err := statsd.New("observer:8125", statsd.WithTags(globalTags))
	if err != nil {
		log.Fatal(err)
	}
	stressTest := &stressTest{statsdClient}

	statsdClient.Incr("transport_sample.run", nil, 1)
	spansCreated := int64(0)
	spanDiff := int64(0)
	previousSpanSubmit := int64(0)

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, os.Interrupt)
	for {
		select {
		case <-sigs:

			// Submit last batch of live counting
			spanDiff := spansCreated - previousSpanSubmit
			statsdClient.Count("transport_sample.span_created", spanDiff, nil, 1)

			fmt.Printf("Finishing at: %v\n", time.Now().Unix())
			fmt.Printf("Spans created: %f\n", spansCreated)
	        statsdClient.Count("transport_sample.span_logged", spansCreated, nil, 1)
	        statsdClient.Incr("transport_sample.end", nil, 1)
			time.Sleep(5 * time.Second)
			statsdClient.Close()
			os.Exit(0)
		default:
			stressTest.createTrace()
			spansCreated = spansCreated + 2
			spanDiff = spansCreated - previousSpanSubmit

			if spanDiff > 499 {
				statsdClient.Count("transport_sample.span_created", spanDiff, nil, 1)
				previousSpanSubmit = spansCreated
			}
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
	span := tracer.StartSpan("spam", tracer.ResourceName("spammer"))
	defer span.Finish()

	childSpan := tracer.StartSpan("nested-spam", tracer.ChildOf(span.Context()))
	time.Sleep(time.Millisecond)
	childSpan.Finish()
}
