#!/bin/bash

set -euo pipefail

FIRMWARE="go60.uf2"

# --- Build ---
echo "🔨 Building firmware..."
./build.sh "$@"

if [[ ! -f "$FIRMWARE" ]]; then
  echo "❌ Build failed: $FIRMWARE not found"
  exit 1
fi
echo "✅ Build complete: $FIRMWARE"
echo

# --- Flash helper ---
flash_half() {
  local label="$1"
  local name="$2"

  echo "⌨️  Put the $name half into bootloader mode (Magic + Tab), then press Enter..."
  read -r

  echo "⏳ Waiting for $label to appear..."
  local dev=""
  for _ in $(seq 1 60); do
    dev=$(lsblk -o NAME,LABEL -rn 2>/dev/null | awk -v l="$label" '$2 == l { print "/dev/" $1; exit }')
    [[ -n "$dev" ]] && break
    sleep 0.5
  done

  if [[ -z "$dev" ]]; then
    echo "❌ Timed out waiting for $label (30s)"
    exit 1
  fi
  echo "   Found $label at $dev"

  # Mount via udisksctl (auto-mounts to /run/media/$USER/$label)
  echo "   Mounting..."
  udisksctl mount -b "$dev" --no-user-interaction 2>/dev/null || true
  local mountpoint="/run/media/$USER/$label"

  if [[ ! -d "$mountpoint" ]]; then
    echo "❌ Mount point $mountpoint does not exist"
    exit 1
  fi

  echo "   Copying $FIRMWARE → $mountpoint/"
  cp "$FIRMWARE" "$mountpoint/"
  sync

  echo "✅ $name half flashed!"

  # The device auto-disconnects after a successful flash, wait a moment
  sleep 2
  echo
}

# --- Flash both halves ---
flash_half "GO60RHBOOT" "right"
flash_half "GO60LHBOOT" "left"

echo "🎉 Done! Both halves flashed."
