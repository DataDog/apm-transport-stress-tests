require 'datadog/statsd'
require 'ddtrace'

class Spammer
  attr_reader \
    :metrics,
    :results

  def initialize
    # Setup metrics
    @metrics = Datadog::Statsd.new('observer', 8125, tags: ["transport:#{ENV['TRANSPORT']}","conc:#{ENV['CONCURRENT_SPAMMERS']}","trunid:#{ENV['TRANSPORT_RUN_ID']}","env:#{ENV['DD_ENV']}","service:#{ENV['DD_SERVICE']}","version:#{ENV['DD_VERSION']}","language:ruby"])
    @results = {}
  end

  def run!

    metrics.count('transport_sample.run', 1)

    results[:traces_generated] = 0
    results[:spans_generated] = 0

    puts "[#{Time.now.utc}] Starting spammer!\n"

    100000000.times do
      generate_trace!
    end

    results
  end

  def close!
    metrics.close
  end

  def generate_trace!
    Datadog::Tracing.trace('spam', resource: 'spammer') do
      Datadog::Tracing.trace('nested-spam') do
        span_created(2)
        sleep(0.001)
      end
    end

    trace_created
  end

  def print_setup!
    puts "--------------"
    puts "Spammer setup:"
    puts "--------------"
    puts "Tracing:"
    puts "- Enabled:   #{Datadog.configuration.tracing.enabled}"
    puts "- Adapter:   #{Datadog::Tracing.send(:tracer).writer.transport.client.api.adapter.class.name}"
    puts "--------------"
  end

  def print_results!
    puts "--------------"
    puts "Spammer results:"
    puts "--------------"
    puts "Traces generated: #{results[:traces_generated]}"
    puts "Spans generated:  #{results[:spans_generated]}"
    puts "--------------"
  end

  def send_final_metrics!
    metrics.count('transport_sample.span_logged', results[:spans_generated])
    metrics.count('transport_sample.end', 1)
    puts "Final metrics sent."
  end

  private

  def trace_created(count = 1)
    results[:traces_generated] += count
  end

  def span_created(count = 1)
    results[:spans_generated] += count
    metrics.count('transport_sample.span_created', count)
  end
end

begin
  # Wait for agent to be ready
  puts "[#{Time.now.utc}] Waiting ten seconds for agent to be ready\n"
  sleep(ENV['DELAY_TIME'] || 10)

  # Create a spammer
  spammer = Spammer.new
  spammer.print_setup!

  # Begin spamming
  spammer.run!

  # Print spam results
  puts "[#{Time.now.utc}] Spammer completed."
  spammer.print_results!
rescue Interrupt
  puts "[#{Time.now.utc}] Spammer gracefully stopping..."

  spammer.print_results! if spammer
ensure
  if spammer
    spammer.send_final_metrics!
    spammer.close!
  end

  puts "[#{Time.now.utc}] Spammer exit."
end
