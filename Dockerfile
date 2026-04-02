FROM docker.io/zmkfirmware/zmk-build-arm:4.1

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY --chmod=755 <<'ENTRYPOINT' /bin/entrypoint.sh
#!/bin/bash
set -euo pipefail
: "${BRANCH:=go60-main}"

cd /zmk

if [ ! -d ".git" ]; then
  echo "Cloning mgabor3141/zmk ($BRANCH)..." >&2
  git clone --depth 5 -b "$BRANCH" https://github.com/mgabor3141/zmk.git /zmk
else
  echo "Updating to $BRANCH..." >&2
  git fetch origin "$BRANCH" --depth 5
  git checkout -q FETCH_HEAD
fi

if [ ! -d "zephyr" ]; then
  echo "Initializing west workspace..." >&2
  west init -l app
fi

echo "Running west update..." >&2
west update --fetch-opt=--filter=tree:0 2>&1 | tail -5
west zephyr-export 2>&1 | tail -2

# Remove Zephyr's built-in cirque pinnacle driver to avoid conflict
# with petejohanson's cirque-input-module (which has z-min filtering)
rm -f /zmk/zephyr/dts/bindings/input/cirque,pinnacle-*.yaml
rm -f /zmk/zephyr/drivers/input/input_pinnacle.c
sed -i '/Kconfig.pinnacle/d' /zmk/zephyr/drivers/input/Kconfig
sed -i '/input_pinnacle/d' /zmk/zephyr/drivers/input/CMakeLists.txt

# Disable GlideExtend (tap-and-drag) on Cirque trackpads
sed -i 's/PINNACLE_FEED_CFG2_EN_BTN_SCRL/PINNACLE_FEED_CFG2_EN_BTN_SCRL | PINNACLE_FEED_CFG2_DIS_GE/' cirque-input-module/drivers/input/input_pinnacle.c

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
