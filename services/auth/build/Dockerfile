FROM golang:1.17.6 as builder
ENV CGO_ENABLED=0 GOOS=linux
WORKDIR /tmp/auth
RUN git init && \
    git remote add origin https://codeberg.org/coldwire/auth.git && \
    git pull origin main
RUN go build -a -o /tmp/auth/main .

FROM scratch
COPY --from=builder /tmp/auth/main /main
COPY --from=builder /tmp/auth/views /views
COPY --from=builder /tmp/auth/static /static
ENTRYPOINT ["/main"]