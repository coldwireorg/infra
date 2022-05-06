# Building docker for multiarch
Since coldwire is a newtwork made of different kind of hardware, we need to build images for multiples arch

First install the build tools for multiarch
```sh
docker run --privileged --rm tonistiigi/binfmt --install all
```

Then create the builder with docker buildx
```sh
docker buildx create --use
```

Then build using the build script in the build folder of every services
