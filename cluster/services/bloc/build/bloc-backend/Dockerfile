FROM golang:1.17.6 as builder
ENV CGO_ENABLED=0 GOOS=linux
WORKDIR /tmp/bloc
RUN git init && \
    git remote add origin https://codeberg.org/coldwire/bloc-backend.git && \
    git pull origin main
RUN go build -a -o /tmp/bloc/main .

FROM scratch
COPY --from=builder /tmp/bloc/main /main
ENTRYPOINT ["/main"]