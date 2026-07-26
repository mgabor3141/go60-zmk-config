#!/bin/bash

set -euo pipefail

IMAGE=go60-zmk-config-docker
REVISION="${1:-5b071c50500ecbf45545516789160e21c83ce190}"

docker build -t "$IMAGE" .
docker run --rm \
  -v "$PWD:/config" \
  -v go60-zmk-src:/zmk \
  -v go60-build-cache:/build \
  -e UID="$(id -u)" -e GID="$(id -g)" -e REVISION="$REVISION" \
  "$IMAGE"
