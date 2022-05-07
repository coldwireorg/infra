docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/auth:v0.3.6 \
  --no-cache \
  --push \
  .
