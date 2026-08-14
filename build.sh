#!/bin/bash

set -euo pipefail

IMAGE=go60-zmk-config-docker
REVISION="${1:-eca8146653f9c8075b20e4b570e1bbae10151368}"

docker build -t "$IMAGE" .
docker run --rm \
  -v "$PWD:/config" \
  -v go60-zmk-src:/zmk \
  -v go60-build-cache:/build \
  -e UID="$(id -u)" -e GID="$(id -g)" -e REVISION="$REVISION" \
  "$IMAGE"
