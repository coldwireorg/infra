docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/auth:v0.0.7 \
  --no-cache \
  --push \
  .