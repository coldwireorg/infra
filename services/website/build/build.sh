docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/website:v0.1.0 \
  --no-cache \
  --push \
  .