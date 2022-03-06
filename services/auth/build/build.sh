docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/auth:v0.0.4 \
  --no-cache \
  --push \
  .