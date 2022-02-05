docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/bloc-frontend:v0.1.0 \
  --build-arg API_BASE=https://api.bloc.coldwire.org \
  --no-cache \
  --push \
  .