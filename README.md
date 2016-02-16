# Docker Proxy

Single-minded reverse proxy that uses the Docker API to build its routing table.

# Quick Start

## Set Up The Environment

```bash
eval "$(docker-machine env --swarm swarm-00)"
```

## Copy The TLS Files

```bash
cp -R ${DOCKER_CERT_PATH} private/docker
```

## Build The Image

``bash
docker build -t docker-proxy .
```

## Run The Container

To run the container, we need to export the `DOCKER` environment variables

```bash
docker run \
  -e DOCKER_HOST \
  -e DOCKER_TLS_VERIFY \
  -e DOCKER_CERT_PATH=/usr/src/app/private/docker \
  -p 80:80 \
  -d docker-proxy:latest
```
