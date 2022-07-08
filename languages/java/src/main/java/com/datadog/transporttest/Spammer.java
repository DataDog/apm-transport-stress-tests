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
                "version:" + System.getenv("DD_VERSION")
        };

        StatsDClient observer = new NonBlockingStatsDClientBuilder()
                .hostname("observer")
                .port(8125)
                // make sure all the metrics are sent before shutdown
                .blocking(true)
                .constantTags(constantTags)
                // TODO: do we need StatsD client metrics?
                // disable StatsD Client metrics
                .enableTelemetry(false)
                .bufferPoolSize(512 * 4) // default 512
                .errorHandler(e -> log.error("StatsDClient error: ", e))
                .enableAggregation(true)
                .aggregationFlushInterval(1000)
                .aggregationShards(8)
                .build();

        final DDTracer tracer = DDTracer.builder()
                // TODO: do we need java-tracer metrics?
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

    private Spammer(StatsDClient observer, DDTracer tracer) {
        this.observer = observer;
        this.tracer = tracer;
    }

    private void run() throws InterruptedException {
        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                observer.increment("transport_sample.span_logged", spansCreated);
                observer.increment("transport_sample.end");
                observer.close();
                log.info("Ended spammer");
            }
        });
        observer.increment("transport_sample.run");
        for (;;) {
            final Span span = tracer.buildSpan("spam").withResourceName("spammer").start();
            try (final Scope scope = tracer.activateSpan(span)) {
                incrementSpans();
                final Span nestedSpan = tracer.buildSpan("nested-spam").asChildOf(span).start();
                try (final Scope nestedScope = tracer.activateSpan(nestedSpan)) {
                    incrementSpans();
                    Thread.sleep(1);
                }
                nestedSpan.finish();
            }
            span.finish();
        }
    }

    private void incrementSpans() {
        observer.increment("transport_sample.span_created");
        spansCreated += 1;
    }
}
