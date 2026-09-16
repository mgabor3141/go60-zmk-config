#!/usr/bin/env python3
"""
Decode ZMK keyboard HID reports and print only on state changes.
Only prints when a key/modifier is pressed or released.

Usage: sudo python3 scripts/hid-decode.py [hidraw_device]
Default device: /dev/hidraw1
"""
import os
import sys
import time

MOD_NAMES = [
    (0x01, "LCtrl"), (0x02, "LShft"), (0x04, "LAlt"), (0x08, "LGui"),
    (0x10, "RCtrl"), (0x20, "RShft"), (0x40, "RAlt"), (0x80, "RGui"),
]

KEY_NAMES = {
    0x04: "A",  0x05: "B",  0x06: "C",  0x07: "D",  0x08: "E",
    0x09: "F",  0x0A: "G",  0x0B: "H",  0x0C: "I",  0x0D: "J",
    0x0E: "K",  0x0F: "L",  0x10: "M",  0x11: "N",  0x12: "O",
    0x13: "P",  0x14: "Q",  0x15: "R",  0x16: "S",  0x17: "T",
    0x18: "U",  0x19: "V",  0x1A: "W",  0x1B: "X",  0x1C: "Y",
    0x1D: "Z",  0x1E: "1",  0x1F: "2",  0x20: "3",  0x21: "4",
    0x22: "5",  0x23: "6",  0x24: "7",  0x25: "8",  0x26: "9",
    0x27: "0",  0x28: "Enter", 0x29: "Esc",  0x2A: "Bksp",
    0x2B: "Tab",  0x2C: "Space", 0x2D: "-",  0x2E: "=",
    0x2F: "[",  0x30: "]",  0x31: "\\", 0x32: "#~", 0x33: ";",
    0x34: "'",  0x35: "`",  0x36: ",",  0x37: ".",  0x38: "/",
    0x39: "CapsLk",
    0x4A: "Home", 0x4B: "PgUp", 0x4C: "End", 0x4D: "PgDn",
    0x4F: "Right", 0x50: "Left", 0x51: "Down", 0x52: "Up",
    # Consumer page codes that ZMK places in the key array
    0x9B: "K_CANCEL",
}

def parse_report(data):
    """Parse a 9-byte HID boot-keyboard report: [report_id, mods, reserved, k1..k6]."""
    if len(data) < 9:
        return None, None
    mods = data[1]
    keys = sorted(b for b in data[3:9] if b)
    return mods, keys

def format_state(mods, keys):
    parts = []
    for bit, name in MOD_NAMES:
        if mods & bit:
            parts.append(name)
    for k in keys:
        parts.append(KEY_NAMES.get(k, f"0x{k:02X}"))
    return " + ".join(parts) if parts else ""

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "/dev/hidraw1"
    try:
        fd = os.open(path, os.O_RDONLY)
    except PermissionError:
        sys.exit(f"Permission denied on {path} — run with sudo")
    except FileNotFoundError:
        sys.exit(f"{path} not found")

    prev_mods = 0
    prev_keys = []
    prev_time = time.monotonic()

    print(f"Decoding {path} — press Ctrl+C to stop\n")

    try:
        while True:
            data = os.read(fd, 64)
            mods, keys = parse_report(data)
            if mods is None:
                continue
            if mods != prev_mods or keys != prev_keys:
                t = time.monotonic()
                dt = (t - prev_time) * 1000
                state = format_state(mods, keys)
                if state:
                    print(f"{dt:7.1f}ms  {state}")
                else:
                    print(f"{dt:7.1f}ms  (released)")
                prev_mods = mods
                prev_keys = keys
                prev_time = t
    except KeyboardInterrupt:
        pass
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
