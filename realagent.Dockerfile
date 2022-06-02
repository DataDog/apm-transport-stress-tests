FROM datadog/agent

EXPOSE 9126/tcp
EXPOSE 9125/udp

RUN mkdir /var/run/datadog; \
    chmod -R a+rwX /var/run/datadog
