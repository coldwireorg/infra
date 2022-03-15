## Builder
FROM node:17.6.0-alpine3.15 as builder
WORKDIR /src
RUN git init && \
    git remote add origin https://codeberg.org/coldwire/cinny.git && \
    git pull origin dev
RUN npm ci
COPY . /src/
RUN npm run build

## App
FROM nginx:1.21.6-alpine
COPY --from=builder /src/dist /app
RUN rm -rf /usr/share/nginx/html \
  && ln -s /app /usr/share/nginx/html