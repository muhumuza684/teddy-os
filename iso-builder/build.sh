#!/bin/bash
# =================================================================
#  TEDDY OS - ISO Build System (local, one command)
#  Built by Bryt Ma Tech UG
#
#  Runs the same two stages that GitHub Actions runs, in order:
#    1. build-rootfs.sh  - Debian root filesystem + desktop app
#    2. build-image.sh   - bootable BIOS/UEFI ISO
#  Requires: Ubuntu 22.04/24.04 (x86_64), root, and a built desktop
#  (cd desktop && npm ci && npm run build). Tools: see iso-builder/README.md
#  Output: iso-builder/teddyos-<version>-x86_64.iso
# =================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

[[ $EUID -eq 0 ]] || { echo "Must run as root: sudo bash build.sh" >&2; exit 1; }

bash ./build-rootfs.sh
bash ./build-image.sh
