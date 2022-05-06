docker run -it --rm --privileged tonistiigi/binfmt --install all

docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag coldwireorg/bloc-frontend:v0.1.4 \
  --build-arg API_BASE=https://bloc.coldwire.org/api \
  --no-cache \
  --push \
  .
