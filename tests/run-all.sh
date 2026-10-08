#!/usr/bin/env bash
# Runs every Teddy OS system-feature test. Linux only (the disk tests need root + loop devices).
#   sudo apt-get install -y nodejs npm xvfb x11-xserver-utils gdisk ntfs-3g parted dosfstools mtools
#   sudo bash tests/run-all.sh
cd "$(dirname "$0")"
set -e
[ -d node_modules ] || npm ci --no-audit --no-fund
sh sync.sh
echo "== 1/4 components + system bridge (vitest) =="; xvfb-run -a npx vitest run
echo "== 2/4 real Electron <webview> (optional) =="
if [ -x electron-webview/node_modules/electron/dist/electron ]; then
  xvfb-run -a electron-webview/node_modules/electron/dist/electron --no-sandbox --disable-gpu electron-webview/main.cjs | grep RESULT
else echo "skipped (run: cd tests/electron-webview && npm i electron)"; fi
echo "== 3/4 install-alongside disk safety =="; bash ../tools/test-alongside.sh
echo "== 4/4 real install.sh end to end (scratch disks) =="; bash ./install-flow.sh
