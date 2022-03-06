FROM golang:1.17.6-bullseye as builder
WORKDIR /tmp/auth
RUN git init && \
    git remote add origin https://codeberg.org/coldwire/auth.git && \
    git pull origin main
RUN go build -o /tmp/auth/main .

FROM scratch
COPY --from=builder /tmp/auth/main /main
COPY --from=builder /tmp/auth/views /views
COPY --from=builder /tmp/auth/static /static
ENTRYPOINT ["/main"]