FROM golang:1.17.6 as builder
ENV CGO_ENABLED=0 GOOS=linux
WORKDIR /tmp/website
RUN git init && \
    git remote add origin https://codeberg.org/coldwire/website.git && \
    git pull origin main
RUN go build -a -o /tmp/website/main .

FROM scratch
COPY --from=builder /tmp/website/main /main
COPY --from=builder /tmp/website/static /static
COPY --from=builder /tmp/website/views /views
ENTRYPOINT ["/main"]