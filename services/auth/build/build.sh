docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/auth:v0.3.1 \
  --no-cache \
  --push \
  .
