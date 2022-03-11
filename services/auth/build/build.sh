docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/auth:v0.1.1 \
  --no-cache \
  --push \
  .