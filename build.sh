#!/bin/bash

set -euo pipefail

IMAGE=go60-zmk-config-docker
BRANCH="${1:-rgb-layer-24.12}"

docker build -t "$IMAGE" .
docker run --rm \
  -v "$PWD:/config" \
  -v go60-nix-store:/nix \
  -v go60-build-cache:/build \
  -e UID="$(id -u)" -e GID="$(id -g)" -e BRANCH="$BRANCH" \
  "$IMAGE"
