FROM nixpkgs/nix:nixos-23.11

ENV PATH=/root/.nix-profile/bin:/usr/bin:/bin

RUN <<EOF
    set -euo pipefail
    nix-env -iA cachix -f https://cachix.org/api/v1/install
    cachix use moergo-glove80-zmk-dev
    mkdir /config
    # Mirror ZMK repository (mgabor3141 fork with per-key RGB + fixes)
    git clone --mirror https://github.com/mgabor3141/zmk /zmk
    GIT_DIR=/zmk git worktree add --detach /src
EOF

# Prepopulate the nix store with build dependencies
RUN <<EOF
    cd /src
    git checkout -q --detach rgb-layer-24.12
    nix-shell --run true -A zmk ./default.nix
EOF

COPY --chmod=755 <<'ENTRYPOINT' /bin/entrypoint.sh
#!/usr/bin/env bash
set -euo pipefail
: "${BRANCH:=rgb-layer-24.12}"

echo "Checking out $BRANCH from mgabor3141/zmk" >&2
cd /src
git fetch origin
git checkout -q --detach "$BRANCH"

echo 'Building Go60 firmware' >&2

# Use nix-shell for the toolchain, but cmake directly for incremental builds.
# Build dirs persist via Docker volume mount at /build.
nix-shell --run '
set -euo pipefail

ZEPHYR_BASE=$(echo /nix/store/*-zephyr/zephyr | head -1)
TOOLCHAIN=$(echo /nix/store/*-gcc-arm-embedded-*/bin/arm-none-eabi-gcc | head -1)
TOOLCHAIN=${TOOLCHAIN%/bin/arm-none-eabi-gcc}
MODULES=$(find /nix/store -maxdepth 2 -name zephyr -type d 2>/dev/null | \
  grep -v "^${ZEPHYR_BASE}$" | \
  sed "s|/zephyr$||" | sort -u | tr "\n" ";" | sed "s/;$//" )

CMAKE_COMMON=(
  -GNinja
  -DZEPHYR_BASE="$ZEPHYR_BASE"
  -DBOARD_ROOT=/src/app
  -DZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
  -DGNUARMEMB_TOOLCHAIN_PATH="$TOOLCHAIN"
  -DCMAKE_C_COMPILER="$TOOLCHAIN/bin/arm-none-eabi-gcc"
  -DCMAKE_CXX_COMPILER="$TOOLCHAIN/bin/arm-none-eabi-g++"
  -DCMAKE_AR="$TOOLCHAIN/bin/arm-none-eabi-ar"
  -DCMAKE_RANLIB="$TOOLCHAIN/bin/arm-none-eabi-ranlib"
  -DZEPHYR_MODULES="$MODULES"
  -DKEYMAP_FILE=/config/config/go60.keymap
  -DEXTRA_CONF_FILE=/config/config/go60.conf
  -DUSER_CACHE_DIR=/build/.cache
)

build_half() {
  local board=$1 build_dir=/build/$board
  echo "=== Building $board ===" >&2
  mkdir -p "$build_dir"
  if [ ! -f "$build_dir/build.ninja" ]; then
    cmake -S /src/app -B "$build_dir" "${CMAKE_COMMON[@]}" -DBOARD="$board"
  else
    # Re-run cmake to pick up config changes
    cmake -B "$build_dir"
  fi
  ninja -C "$build_dir" -j2
}

build_half go60_lh
build_half go60_rh

mkdir -p /tmp/combined
cat /build/go60_lh/zephyr/zmk.uf2 /build/go60_rh/zephyr/zmk.uf2 > /tmp/combined/go60.uf2
' -A zmk /src/default.nix

install -o "$UID" -g "$GID" /tmp/combined/go60.uf2 /config/go60.uf2
echo "Done: go60.uf2" >&2
ENTRYPOINT

ENTRYPOINT ["/bin/entrypoint.sh"]

# Run build.sh to use this file
