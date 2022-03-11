docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/auth:v0.1.0 \
  --no-cache \
  --push \
  .