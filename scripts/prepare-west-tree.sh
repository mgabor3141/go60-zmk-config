#!/usr/bin/env bash
set -euo pipefail

# Make the two west projects safe for this configuration.  Always begin at the
# checked-out revisions so this is idempotent in persistent west workspaces.
workspace="${1:-/zmk}"
zephyr="$workspace/zephyr"
cirque="$workspace/cirque-input-module"

zephyr_files=(
  drivers/input/Kconfig
  drivers/input/CMakeLists.txt
  drivers/input/input_pinnacle.c
  "dts/bindings/input/cirque,pinnacle-common.yaml"
  "dts/bindings/input/cirque,pinnacle-i2c.yaml"
  "dts/bindings/input/cirque,pinnacle-spi.yaml"
)
cirque_file=drivers/input/input_pinnacle.c

for repo in "$zephyr" "$cirque"; do
  if [[ ! -d "$repo/.git" && ! -f "$repo/.git" ]]; then
    echo "Expected west git project not found: $repo" >&2
    exit 1
  fi
done

# Validate every input directly from the checked-out commits before touching the
# worktrees. This keeps an unsupported upstream revision from being half-applied.
python3 - "$zephyr" "$cirque" "${zephyr_files[@]}" <<'PY'
import subprocess
import sys
from pathlib import Path

zephyr = Path(sys.argv[1])
cirque = Path(sys.argv[2])
zephyr_files = sys.argv[3:]


def head_file(repo, path):
    result = subprocess.run(
        ["git", "-C", str(repo), "show", f"HEAD:{path}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode:
        raise SystemExit(f"{repo}: required HEAD file missing: {path}")
    return result.stdout.decode()


def require_once(repo, path, needle):
    count = head_file(repo, path).count(needle)
    if count != 1:
        raise SystemExit(
            f"{repo / path}: expected exactly one {needle!r} in HEAD, found {count}"
        )


# Reading all deletion targets verifies that they exist in HEAD.
for path in zephyr_files[2:]:
    head_file(zephyr, path)
require_once(zephyr, zephyr_files[0], 'source "drivers/input/Kconfig.pinnacle"\n')
require_once(
    zephyr,
    zephyr_files[1],
    "zephyr_library_sources_ifdef(CONFIG_INPUT_PINNACLE input_pinnacle.c)\n",
)
require_once(
    cirque,
    "drivers/input/input_pinnacle.c",
    "PINNACLE_FEED_CFG2_EN_IM | PINNACLE_FEED_CFG2_EN_BTN_SCRL;",
)
PY

# Restore the worktree from HEAD explicitly; do not trust a possibly modified
# index in a persistent/local west project.
git -C "$zephyr" restore --source=HEAD --worktree -- "${zephyr_files[@]}"
git -C "$cirque" restore --source=HEAD --worktree -- "$cirque_file"

python3 - "$zephyr" "$cirque/$cirque_file" <<'PY'
from pathlib import Path
import sys

zephyr = Path(sys.argv[1])
cirque_driver = Path(sys.argv[2])

replacements = (
    (
        zephyr / "drivers/input/Kconfig",
        'source "drivers/input/Kconfig.pinnacle"\n',
        "",
    ),
    (
        zephyr / "drivers/input/CMakeLists.txt",
        "zephyr_library_sources_ifdef(CONFIG_INPUT_PINNACLE input_pinnacle.c)\n",
        "",
    ),
    (
        cirque_driver,
        "PINNACLE_FEED_CFG2_EN_IM | PINNACLE_FEED_CFG2_EN_BTN_SCRL;",
        "PINNACLE_FEED_CFG2_EN_IM | PINNACLE_FEED_CFG2_EN_BTN_SCRL | PINNACLE_FEED_CFG2_DIS_GE;",
    ),
)
for path, old, new in replacements:
    path.write_text(path.read_text().replace(old, new))
PY

rm -- \
  "$zephyr/drivers/input/input_pinnacle.c" \
  "$zephyr/dts/bindings/input/cirque,pinnacle-common.yaml" \
  "$zephyr/dts/bindings/input/cirque,pinnacle-i2c.yaml" \
  "$zephyr/dts/bindings/input/cirque,pinnacle-spi.yaml"

echo "Prepared Zephyr and cirque-input-module sources" >&2
