FROM php:8.1-cli
COPY ./ .
RUN curl -LO https://github.com/DataDog/dd-trace-php/releases/latest/download/datadog-setup.php
RUN php datadog-setup.php --php-bin=all

ENV DD_TRACE_CLI_ENABLED 1
ENV DD_TRACE_GENERATE_ROOT_SPAN 0
ENV DD_TRACE_AUTO_FLUSH_ENABLED 1

CMD ["php", "long-running-script.php"]
