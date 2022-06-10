FROM python:3.9
COPY ./ /app
WORKDIR /app
RUN ./install_ddtrace.sh
CMD ["ddtrace-run", "python", "Spammer.py"]