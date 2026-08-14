#!/bin/bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

YAML_TMP=$(mktemp)
SVG_TMP=$(mktemp)
trap 'rm -f "$YAML_TMP" "$SVG_TMP"' EXIT

KEYMAP=(uvx --from keymap-drawer keymap -c keymap_drawer.config.yaml)

"${KEYMAP[@]}" parse -z config/go60.keymap \
  --layer-names Base Nav Symbol Function WM Gaming Mouse Magic \
  >"$YAML_TMP"

"${KEYMAP[@]}" draw "$YAML_TMP" -j config/info.json \
  --select-layers Base Nav Symbol Function Gaming Magic \
  >"$SVG_TMP"

mv "$YAML_TMP" keymap-drawer/go60.yaml
mv "$SVG_TMP" keymap-drawer/go60.svg

echo "Updated keymap-drawer/go60.yaml and keymap-drawer/go60.svg"
