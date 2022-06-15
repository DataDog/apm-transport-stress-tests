require 'ddtrace/auto_instrument'

Datadog.configure do |c|
  # Add additional configuration here.
end

print "Waiting ten seconds for agent to be ready\n"

sleep(10)

print "Starting spammer!\n"

limit = 100000000
 
while limit >= 1
  Datadog::Tracing.trace('spam', resource: 'spammer') do |span|
    Datadog::Tracing.trace('nested-spam') do
      sleep(0.001)
    end
  end
  limit = limit - 1
end