FROM ruby:3.1.2

WORKDIR /app

COPY Gemfile .
RUN bundle install

COPY spammer.rb .

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["bundle exec ruby spammer.rb"]
