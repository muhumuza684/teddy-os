#!/usr/bin/env bash
set -euo pipefail

echo '=== Teddy OS performance snapshot ==='
printf 'Kernel: '; uname -sr
printf 'RAM: '; free -h | awk '/^Mem:/ {print $3 " used / " $2 " total"}'
printf 'Root filesystem: '; df -h / | awk 'NR==2 {print $3 " used / " $2 " total"}'
printf 'Uptime: '; uptime -p
if command -v systemd-analyze >/dev/null 2>&1; then
  systemd-analyze || true
  echo '=== Slow services ==='
  systemd-analyze blame | head -15 || true
fi
if command -v ps >/dev/null 2>&1; then
  echo '=== Largest processes ==='
  ps -eo pid,comm,%mem,rss --sort=-rss | head -15
fi
