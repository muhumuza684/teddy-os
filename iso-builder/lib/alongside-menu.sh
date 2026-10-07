#!/usr/bin/env bash
# Interactive step for install.sh.  Usage inside install.sh:
#   source "$(dirname "$0")/lib/alongside.sh"
#   source "$(dirname "$0")/lib/alongside-menu.sh"
#   alongside_menu "$TARGET_DISK" && echo "Teddy OS partition: $(al_part_dev "$TARGET_DISK" "$AL_NEW_LINUX_NUM")"
# Returns 0 only if the disk was safely shrunk and a Teddy OS partition now exists
# (the installer should then format/install onto AL_NEW_LINUX_NUM and REUSE the existing ESP, $AL_ESP_PART).
alongside_menu() {
  local disk="$1" ans
  echo; echo "== Install alongside Windows =="
  echo "Checking $disk (nothing is changed yet)..."
  if ! al_check "$disk"; then
    echo; echo "Cannot install alongside Windows: $AL_REASON"; return 1
  fi
  echo "Windows found on $AL_WIN_PART. Teddy OS can use about $(( AL_FREED_BYTES / 1048576 / 1024 )) GiB."
  echo "Windows will be shrunk; your partition table is backed up and restored automatically on any failure."
  read -r -p "Type YES to continue: " ans
  [ "$ans" = "YES" ] || { echo "Cancelled."; return 1; }
  al_apply "$disk" || { echo "Failed (nothing was left changed): $AL_REASON"; return 1; }
}
