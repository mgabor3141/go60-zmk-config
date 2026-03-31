# Go60 ZMK Config

## ZMK layer ordering

Alternative base layers (MacBase, etc.) must be low in the stack (just above Base). ZMK resolves key bindings from highest active layer to lowest. If an alt-base is layer 8 and Magic is layer 7, Magic becomes inaccessible when the alt-base is active. We've hit this twice (CapsWord, MacBase).

Rule: Base=0, alt-bases=1..N, then Nav, Symbol, Gaming, ..., Magic at the top.

## Build

Docker-based. `bash build.sh` clones/updates `mgabor3141/zmk:go60-main`, runs west build.
Firmware repo: `~/dev/go60-zmk`. Config repo: `~/dev/go60-zmk-config`.
Clearing build cache: `docker volume rm go60-build-cache go60-zmk-src`.
After firmware changes, clear both volumes. Config-only changes use incremental builds (~45s).

## RGB indicators

Hardcoded in `~/dev/go60-zmk/app/src/rgb_underglow.c`. Layer numbers in indicator tables must match keymap defines. LH (central) only; RH has no layer state access.

## Per-endpoint default layer

`&default_layer N` persists layer N for the current endpoint (USB/BLE profile) to flash. Auto-restores on boot and endpoint change. Config: `CONFIG_ZMK_DEFAULT_LAYER_ENDPOINT=y`.

## HID remap (macOS support)

`&endpoint_os N` sets OS type per endpoint (0=Linux, 1=macOS). Persists to flash, auto-applies on endpoint change. Config: `CONFIG_ZMK_HID_REMAP=y`.

When macOS is active, the HID report is rewritten before sending:
- Phase 1: modifier bit swap (LCTRL<->LGUI, RGUI->LCTRL)
- Phase 2: key-specific overrides (word nav, Tab un-swap, Home/End, F13/F21)

This means ALL layers work correctly on macOS without duplication. The remap operates on a temporary copy of the report; ZMK's internal state is unaffected.

The remap replaces kanata's go60.kbd config entirely. kanata is no longer needed for the Go60 on macOS.
