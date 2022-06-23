FROM python:3.9
COPY ./ .
RUN ./install_ddtrace.sh
# RUN pip install ddtrace
CMD ["ddtrace-run", "python", "Spammer.py"]