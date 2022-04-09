FROM node:17.2-bullseye as frontend
WORKDIR /tmp/auth
RUN git init && \
    git remote add origin https://codeberg.org/coldwire/auth.git && \
    git pull origin main
WORKDIR /tmp/auth/views
RUN npm i
RUN npm run build

FROM golang:1.17.6 as backend
ENV CGO_ENABLED=0 GOOS=linux
WORKDIR /tmp/auth
COPY --from=frontend /tmp/auth/ /tmp/auth/
RUN go build -a -o /tmp/auth/main .

FROM scratch
COPY --from=backend /tmp/auth/main /main
ENTRYPOINT ["/main"]