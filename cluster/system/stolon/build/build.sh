docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/postgres:v0.0.1 \
  --push \
  .
