FROM datadog/agent

EXPOSE 6126/tcp
EXPOSE 6125/udp

RUN mkdir /var/run/datadog; \
    chmod -R a+rwX /var/run/datadog
