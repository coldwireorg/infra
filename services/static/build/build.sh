docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/static:v0.0.1 \
  --no-cache \
  --push \
  .