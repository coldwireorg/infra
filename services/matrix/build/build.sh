docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/cinny:v1.0.0 \
  --no-cache \
  --push \
  .