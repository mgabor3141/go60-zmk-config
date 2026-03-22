#!/bin/bash

set -euo pipefail

IMAGE=go60-zmk-config-docker
BRANCH="${1:-main}"

docker build -t "$IMAGE" .
docker run --rm \
  -v "$PWD:/config" \
  -v go60-nix-store:/nix \
  -e UID="$(id -u)" -e GID="$(id -g)" -e BRANCH="$BRANCH" \
  "$IMAGE"
