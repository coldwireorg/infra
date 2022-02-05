docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/bloc-frontend:v0.1.1 \
  --build-arg API_BASE=https://bloc.coldwire.org/api \
  --no-cache \
  --push \
  .