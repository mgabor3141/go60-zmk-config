FROM docker.io/zmkfirmware/zmk-build-arm:4.1

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY --chmod=755 <<'ENTRYPOINT' /bin/entrypoint.sh
#!/bin/bash
set -euo pipefail
: "${REVISION:=eca8146653f9c8075b20e4b570e1bbae10151368}"

cd /zmk

if [ ! -d ".git" ]; then
  echo "Cloning mgabor3141/zmk ($REVISION)..." >&2
  git init -q
  git remote add origin https://github.com/mgabor3141/zmk.git
else
  echo "Updating to $REVISION..." >&2
fi
git fetch origin "$REVISION" --depth 5
git checkout --detach --force -q FETCH_HEAD

if [ ! -d "zephyr" ]; then
  echo "Initializing west workspace..." >&2
  west init -l app
fi

echo "Running west update..." >&2
west update --fetch-opt=--filter=tree:0 2>&1 | tail -5
west zephyr-export 2>&1 | tail -2

# Resolve the in-tree/external Pinnacle collision and disable GlideExtend.
# The helper restores the affected files first, so persistent volumes are safe.
/config/scripts/prepare-west-tree.sh /zmk

build_half() {
  local board=$1
  echo "=== Building $board ===" >&2
  west build -p -s app -b "$board" -d "/build/$board" -- \
    -DKEYMAP_FILE=/config/config/go60.keymap \
    -DEXTRA_CONF_FILE=/config/config/go60.conf
}

build_half go60_lh
build_half go60_rh

mkdir -p /tmp/combined
cat /build/go60_lh/zephyr/zmk.uf2 /build/go60_rh/zephyr/zmk.uf2 > /tmp/combined/go60.uf2
install -o "$UID" -g "$GID" /tmp/combined/go60.uf2 /config/go60.uf2
echo "Done: go60.uf2" >&2
ENTRYPOINT

ENTRYPOINT ["/bin/entrypoint.sh"]
