#!/bin/bash

set -euo pipefail

FIRMWARE="go60.uf2"
TIMEOUT=600

# --- Parse flags ---
BUILD=true
for arg in "$@"; do
  if [[ "$arg" == "--no-build" ]]; then
    BUILD=false
  fi
done

# Filter out --no-build from args passed to build.sh
BUILD_ARGS=()
for arg in "$@"; do
  if [[ "$arg" != "--no-build" ]]; then
    BUILD_ARGS+=("$arg")
  fi
done

# --- Build ---
if $BUILD; then
  echo "🔨 Building firmware..."
  ./build.sh "${BUILD_ARGS[@]}"

  if [[ ! -f "$FIRMWARE" ]]; then
    echo "❌ Build failed: $FIRMWARE not found"
    exit 1
  fi
  echo "✅ Build complete: $FIRMWARE"
  echo
else
  if [[ ! -f "$FIRMWARE" ]]; then
    echo "❌ $FIRMWARE not found. Run a build first or drop --no-build."
    exit 1
  fi
  echo "⏭️  Skipping build (--no-build). Using existing $FIRMWARE"
  echo
fi

# --- Helpers ---

# Find block device by partition label, returns e.g. /dev/sdb1 or empty
find_dev_by_label() {
  lsblk -o NAME,LABEL -rn 2>/dev/null | awk -v l="$1" '$2 == l { print "/dev/" $1; exit }'
}

# Wait for a specific label to appear, rejecting the wrong half
wait_and_flash() {
  local expected_label="$1"
  local wrong_label="$2"
  local name="$3"

  # If the correct bootloader is already connected, skip waiting
  local dev
  dev=$(find_dev_by_label "$expected_label")
  if [[ -n "$dev" ]]; then
    echo "⌨️  $name half already in bootloader mode ($expected_label at $dev)"
  else
    echo "⌨️  Put the $name half into bootloader mode now..."

    dev=""
    local elapsed=0
    while (( elapsed < TIMEOUT )); do
      # Check for wrong half first
      local wrong_dev
      wrong_dev=$(find_dev_by_label "$wrong_label")
      if [[ -n "$wrong_dev" ]]; then
        echo ""
        echo "❌ Detected $wrong_label instead of $expected_label!"
        echo "   Please disconnect the wrong half and connect the $name half."
        # Wait for the wrong device to go away
        while [[ -n $(find_dev_by_label "$wrong_label") ]]; do
          sleep 1
        done
        echo "   Wrong device removed. Resuming wait for $expected_label..."
      fi

      dev=$(find_dev_by_label "$expected_label")
      if [[ -n "$dev" ]]; then
        break
      fi

      sleep 0.5
      elapsed=$(( elapsed + 1 ))
    done

    if [[ -z "$dev" ]]; then
      echo "❌ Timed out waiting for $expected_label"
      exit 1
    fi
  fi
  echo "   Found $expected_label at $dev"

  # Mount via udisksctl
  echo "   Mounting..."
  udisksctl mount -b "$dev" --no-user-interaction 2>/dev/null || true
  local mountpoint="/run/media/$USER/$expected_label"

  if [[ ! -d "$mountpoint" ]]; then
    echo "❌ Mount point $mountpoint does not exist"
    exit 1
  fi

  echo "   Copying $FIRMWARE → $mountpoint/"
  cp "$FIRMWARE" "$mountpoint/"
  sync

  echo "✅ $name half flashed!"

  # The device auto-disconnects after a successful flash; wait for it to go
  echo "   Waiting for device to disconnect..."
  while [[ -n $(find_dev_by_label "$expected_label") ]]; do
    sleep 0.5
  done
  sleep 1
  echo
}

# --- Main ---
wait_and_flash "GO60RHBOOT" "GO60LHBOOT" "right"
wait_and_flash "GO60LHBOOT" "GO60RHBOOT" "left"

echo "🎉 Done! Both halves flashed."
