FROM python:3.9
COPY ./ .
RUN pip install ddtrace
CMD ["ddtrace-run", "python", "Spammer.py"]