docker buildx build \
  --platform linux/arm64 \
  --tag coldwireorg/auth:v0.0.1 \
  --no-cache \
  --push \
  .