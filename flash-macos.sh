#!/bin/bash
set -euo pipefail

FIRMWARE="go60.uf2"
TIMEOUT=120

if [[ ! -f "$FIRMWARE" ]]; then
  echo "❌ $FIRMWARE not found. Run a build first."
  exit 1
fi

echo "✅ Using existing $FIRMWARE ($(stat -f%z "$FIRMWARE") bytes)"
echo

# Find UF2 bootloader volume by name, returns mount point or empty
find_bootloader() {
  local label="$1"
  mount | grep "/Volumes/$label" | awk '{print $3}' || true
}

wait_and_flash() {
  local expected_label="$1"
  local wrong_label="$2"
  local name="$3"

  local mountpoint
  mountpoint=$(find_bootloader "$expected_label")

  if [[ -n "$mountpoint" ]]; then
    echo "⌨️  $name half already in bootloader mode ($expected_label)"
  else
    echo "⌨️  Put the $name half into bootloader mode now..."

    local elapsed=0
    while (( elapsed < TIMEOUT )); do
      # Check for wrong half
      local wrong_mount
      wrong_mount=$(find_bootloader "$wrong_label")
      if [[ -n "$wrong_mount" ]]; then
        echo ""
        echo "❌ Detected $wrong_label instead of $expected_label!"
        echo "   Please disconnect the wrong half and connect the $name half."
        while [[ -n $(find_bootloader "$wrong_label") ]]; do
          sleep 1
        done
        echo "   Wrong device removed. Resuming wait for $expected_label..."
      fi

      mountpoint=$(find_bootloader "$expected_label")
      if [[ -n "$mountpoint" ]]; then
        break
      fi

      sleep 0.5
      elapsed=$(( elapsed + 1 ))
    done

    if [[ -z "$mountpoint" ]]; then
      echo "❌ Timed out waiting for $expected_label"
      exit 1
    fi
  fi

  echo "   Found $expected_label at $mountpoint"
  echo "   Copying $FIRMWARE → $mountpoint/"
  cp -X "$FIRMWARE" "$mountpoint/"
  sync

  echo "✅ $name half flashed!"

  # Wait for device to disconnect after flash
  echo "   Waiting for device to disconnect..."
  while [[ -n $(find_bootloader "$expected_label") ]]; do
    sleep 0.5
  done
  sleep 1
  echo
}

wait_and_flash "GO60RHBOOT" "GO60LHBOOT" "right"
wait_and_flash "GO60LHBOOT" "GO60RHBOOT" "left"

echo "🎉 Done! Both halves flashed."
