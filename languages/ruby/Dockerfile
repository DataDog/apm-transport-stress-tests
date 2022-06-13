FROM ruby:3.1.2
WORKDIR /app
COPY ./ .
RUN bundle install && cp Gemfile.lock Gemfile.lock.new
CMD ["ruby", "Spammer.rb"]