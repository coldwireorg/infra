FROM node:17.2.0-bullseye as builder
RUN apt install git
WORKDIR /tmp/bloc
RUN git init && \
    git remote add origin https://codeberg.org/coldwire/bloc-frontend.git && \
    git pull origin main
RUN npm i
ARG API_BASE
ENV VITE_API_BASE $API_BASE
RUN npm run build

FROM node:12.22.10-bullseye-slim
WORKDIR /app
COPY --from=builder /tmp/bloc .
CMD ["node", "./build"]