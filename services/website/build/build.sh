docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/website:v0.0.8 \
  --no-cache \
  --push \
  .