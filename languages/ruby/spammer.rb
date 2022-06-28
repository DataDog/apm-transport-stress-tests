require 'datadog/statsd'
require 'ddtrace'

class Spammer
  attr_reader \
    :metrics

  def initialize
    # Setup metrics
    @metrics = Datadog::Core::Metrics::Client.new
  end

  def run!
    puts "[#{Time.now.utc}] Waiting ten seconds for agent to be ready\n"

    sleep(10)

    puts "[#{Time.now.utc}] Starting spammer!\n"

    100000000.times do
      generate_trace!
    end
  end

  def generate_trace!
    Datadog::Tracing.trace('spam', resource: 'spammer') do |span|
      metrics.increment('transport_sample.span_created')
      Datadog::Tracing.trace('nested-spam') do
        span_created(2)
        sleep(0.001)
      end
    end
  end

  def print_diagnostics!
    puts "Tracing:\n- Enabled: #{Datadog.configuration.tracing.enabled}"
    puts "Metrics:\n- Supported: #{metrics.supported?}\n- Enabled: #{metrics.enabled?}"
  end

  def span_created(count = 1)
    metrics.count('transport_sample.span_created', count)
  end
end

# Run the spammer
begin
  spammer = Spammer.new
  spammer.print_diagnostics!
  spammer.run!
ensure
  puts "[#{Time.now.utc}] Spammer shutting down!"
end
