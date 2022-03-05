docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/static:v0.0.2 \
  --no-cache \
  --push \
  .