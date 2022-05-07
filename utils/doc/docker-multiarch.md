```sh
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --driver-opt network=host --driver docker-container --name builder --use builder
```

