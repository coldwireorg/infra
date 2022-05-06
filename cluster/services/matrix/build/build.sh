docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/cinny:v1.8.2 \
  --no-cache \
  --push \
  .
