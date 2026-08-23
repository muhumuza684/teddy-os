#!/usr/bin/env bash
set -euo pipefail

ISO="${1:-}"
if [[ -z "$ISO" || ! -f "$ISO" ]]; then
  echo "Usage: $0 path/to/teddyos.iso" >&2
  exit 2
fi

printf 'ISO: %s\n' "$ISO"
printf 'Size: '; du -h "$ISO" | cut -f1
printf 'SHA256: '; sha256sum "$ISO"
if command -v isoinfo >/dev/null 2>&1; then
  echo '=== ISO volume metadata ==='
  isoinfo -d -i "$ISO" | grep -E 'Volume id|System id|Application id' || true
fi
echo 'ISO file verification complete. Boot validation must still be performed in QEMU or VirtualBox.'
