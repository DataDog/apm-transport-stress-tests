FROM python:3.9

WORKDIR /app

COPY . .

EXPOSE 9126/tcp
EXPOSE 9125/udp

RUN mkdir /var/run/datadog; \
    chmod -R a+rwX /var/run/datadog
	
RUN mkdir -p /var/log/traces
RUN chmod a+rwx /var/log/traces

RUN mkdir -p /var/log/stats
RUN chmod a+rwx /var/log/stats

ENV PORT=9126
ENV SNAPSHOT_CI=1
ENV LOG_LEVEL=INFO
ENV SNAPSHOT_DIR=/snapshots

# RUN pip install git+https://github.com/Datadog/dd-apm-test-agent
RUN ls
RUN pip /dd-apm-test-agent

CMD ["ddapm-test-agent"]
