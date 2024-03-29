package com.datadog.transporttest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.timgroup.statsd.NonBlockingStatsDClientBuilder;
import com.timgroup.statsd.StatsDClient;
import datadog.opentracing.DDTracer;
import io.opentracing.Scope;
import io.opentracing.Span;
import io.opentracing.util.GlobalTracer;

public class Spammer {
    private static Logger log = LoggerFactory.getLogger(Spammer.class);

    public static void main(String[] args) throws InterruptedException {
        log.info("Sleeping for 10 seconds to wait for agent");
        Thread.sleep(10000);
        log.info("Starting spammer");

        String[] constantTags = new String[] {
                "language:java",
                "transport:" + System.getenv("TRANSPORT"),
                "conc:" + System.getenv("CONCURRENT_SPAMMERS"),
                "trunid:" + System.getenv("TRANSPORT_RUN_ID"),
                "env:" + System.getenv("DD_ENV"),
                "service:" + System.getenv("DD_SERVICE"),
                "version:" + System.getenv("DD_VERSION"),
                "tracer_version:" + datadog.trace.core.DDTraceCoreInfo.VERSION
        };

        StatsDClient observer = new NonBlockingStatsDClientBuilder()
                .hostname("observer")
                .port(8125)
                .constantTags(constantTags)
                // make sure all the metrics are sent before shutdown
                .blocking(true)
                // disable StatsD Client metrics
                .enableTelemetry(false)
                .enableAggregation(true)
                .errorHandler(e -> log.error("StatsDClient error: ", e))
                .build();

        final DDTracer tracer = DDTracer.builder()
                // disables tracer metrics
                .statsDClient(datadog.trace.api.StatsDClient.NO_OP)
                .build();
        GlobalTracer.registerIfAbsent(tracer);
        // register the same tracer with the Datadog API
        datadog.trace.api.GlobalTracer.registerIfAbsent(tracer);

        new Spammer(observer, tracer).run();
    }

    private final StatsDClient observer;
    private final DDTracer tracer;
    private long spansCreated;
    private long previousSpansCreated;

    private Spammer(StatsDClient observer, DDTracer tracer) {
        this.observer = observer;
        this.tracer = tracer;
    }

    private void run() throws InterruptedException {
        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                incrementSpanCreated(1);
                observer.count("transport_sample.span_logged", spansCreated, 1.0);
                observer.increment("transport_sample.end");
                observer.close();
                tracer.close();
                log.info("Ended spammer");
            }
        });
        observer.increment("transport_sample.run");
        while (true) {
            final Span span = tracer.buildSpan("spam").withResourceName("spammer").start();
            try (final Scope scope = tracer.activateSpan(span)) {
                spansCreated += 1;
                final Span nestedSpan = tracer.buildSpan("nested-spam").asChildOf(span).start();
                try (final Scope nestedScope = tracer.activateSpan(nestedSpan)) {
                    spansCreated += 1;
                    Thread.sleep(1);
                }
                nestedSpan.finish();
            }
            span.finish();
            incrementSpanCreated(200);
        }
    }

    private void incrementSpanCreated(int limit) {
        long diff = spansCreated - previousSpansCreated;
        if (diff >= limit) {
            // Batch these so as to not overload dogstatsd
            observer.count("transport_sample.span_created", diff, 1.0);
            previousSpansCreated = spansCreated;
        }
    }
}
