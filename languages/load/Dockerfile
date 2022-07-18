FROM golang:1
RUN go version && curl --version
WORKDIR /app

COPY . ./

RUN go get -v -d -u gopkg.in/DataDog/dd-trace-go.v1

RUN go build -v -o transport-test ./spammer.go

CMD ["./transport-test"]
