FROM golang:1
RUN go version && curl --version
WORKDIR /app

COPY . ./

RUN ./install_ddtrace.sh

RUN go build -v -o transport-test ./spammer.go

CMD ["./transport-test"]
