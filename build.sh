#!/bin/bash

set -euo pipefail

IMAGE=go60-zmk-config-docker
REVISION="${1:-278302d9c2610a6982aede0a20f78150b16915d1}"

docker build -t "$IMAGE" .
docker run --rm \
  -v "$PWD:/config" \
  -v go60-zmk-src:/zmk \
  -v go60-build-cache:/build \
  -e UID="$(id -u)" -e GID="$(id -g)" -e REVISION="$REVISION" \
  "$IMAGE"
