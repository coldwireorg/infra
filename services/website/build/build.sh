docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/website:v0.1.4 \
  --no-cache \
  --push \
  .
