FROM golang:1.17.6 as builder
ENV CGO_ENABLED=0 GOOS=linux
WORKDIR /tmp/static
RUN git init && \
    git remote add origin https://codeberg.org/coldwire/static.git && \
    git pull origin main
RUN go build -a -o /tmp/static/main .

FROM scratch
COPY --from=builder /tmp/static/main /main
ENTRYPOINT ["/main"]