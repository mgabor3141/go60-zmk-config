FROM docker.io/zmkfirmware/zmk-build-arm:4.1

WORKDIR /zmk

# Clone our fork and set up west workspace
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN git clone --depth 5 -b go60-main https://github.com/mgabor3141/zmk.git /zmk && \
    west init -l app && \
    west update --fetch-opt=--filter=tree:0 && \
    west zephyr-export

COPY --chmod=755 <<'ENTRYPOINT' /bin/entrypoint.sh
#!/bin/bash
set -euo pipefail
: "${BRANCH:=go60-main}"

echo "Updating to $BRANCH" >&2
cd /zmk
git fetch origin "$BRANCH" --depth 5
git checkout -q FETCH_HEAD

west update --fetch-opt=--filter=tree:0 2>&1 | tail -3

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
