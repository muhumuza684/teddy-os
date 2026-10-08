#!/usr/bin/env bash
# Test harness for iso-builder/lib/alongside.sh using REAL scratch GPT disks
# (loop devices, actual mkntfs / ntfsresize / sgdisk).  Run as root.
#   sudo tools/test-alongside.sh
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../iso-builder/lib/alongside.sh
source "$HERE/../iso-builder/lib/alongside.sh"

WORK=$(mktemp -d /tmp/al-test.XXXXXX)
export AL_BACKUP_DIR="$WORK/backups"
export AL_MIN_LINUX_MIB=100 AL_WIN_HEADROOM_MIB=20
PASS=0; FAIL=0; LOOPS=()

cleanup() {
  local l
  for l in "${LOOPS[@]}"; do umount "${l}"p* 2>/dev/null; losetup -d "$l" 2>/dev/null; done
  rm -rf "$WORK"
}
trap cleanup EXIT

ok()   { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL  $1  ${2:+($2)}"; }
expect_ok()     { if "${@:2}"; then ok "$1"; else bad "$1" "$AL_REASON"; fi; }
expect_refuse() { # name, reason-regex, cmd...
  local name="$1" rx="$2"; shift 2
  if "$@"; then bad "$name" "should have refused"
  elif echo "$AL_REASON" | grep -qiE "$rx"; then ok "$name"
  else bad "$name" "wrong reason: $AL_REASON"; fi
}

# --- scratch disk builders ---------------------------------------------------
# mkdisk NAME SIZE_MIB  -> sets DISK (loop device with partition scanning)
mkdisk() {
  truncate -s "${2}M" "$WORK/$1.img"
  DISK=$(losetup -f --show -P "$WORK/$1.img") || { echo "loop setup failed"; exit 2; }
  LOOPS+=("$DISK")
}
wait_part() { local i; for i in 1 2 3 4 5 6 7 8 9 10; do [ -b "$1" ] && return 0; partprobe "$DISK" 2>/dev/null; sleep 0.5; done; return 1; }

# win_disk NAME [flavour]   flavour: healthy|hibernated|bitlocker|dirty|full
win_disk() {
  local name="$1" flavour="${2:-healthy}" esp win mnt
  mkdisk "$name" 600
  sgdisk -og "$DISK" >/dev/null
  sgdisk -n 1:2048:+50M  -t 1:EF00 -c 1:"EFI System Partition" "$DISK" >/dev/null
  sgdisk -n 2:0:0        -t 2:0700 -c 2:"Basic data partition" "$DISK" >/dev/null
  partprobe "$DISK"; esp=$(al_part_dev "$DISK" 1); win=$(al_part_dev "$DISK" 2)
  wait_part "$esp" && wait_part "$win" || { echo "no partition nodes"; exit 2; }
  mkfs.vfat -F32 "$esp" >/dev/null 2>&1
  mnt="$WORK/m"; mkdir -p "$mnt"
  : > "$WORK/bootmgfw.efi"   # populated with mtools so no kernel vfat driver is needed
  mmd -i "$esp" ::/EFI ::/EFI/Microsoft ::/EFI/Microsoft/Boot && mcopy -i "$esp" "$WORK/bootmgfw.efi" ::/EFI/Microsoft/Boot/ || { echo "ESP populate failed"; exit 2; }
  mkntfs -F -Q -q "$win" >/dev/null 2>&1
  mount -t ntfs-3g "$win" "$mnt" || { echo "ntfs mount failed"; exit 2; }
  mkdir -p "$mnt/Windows/System32"
  if [ "$flavour" = full ]; then dd if=/dev/urandom of="$mnt/filler.bin" bs=1M count=480 2>/dev/null; fi
  [ "$flavour" = hibernated ] && printf 'hibr\0\0\0\0' > "$mnt/hiberfil.sys"
  umount "$mnt"
  [ "$flavour" = bitlocker ] && printf -- '-FVE-FS-' | dd of="$win" bs=1 seek=3 conv=notrunc 2>/dev/null
  [ "$flavour" = dirty ] && ntfsfix "$win" >/dev/null 2>&1   # sets the "check at next boot" flag
  return 0
}

[ -n "${AL_TEST_LIB_ONLY:-}" ] && return 0   # helpers only (used by tests/install-flow.sh)

echo "== alongside.sh tests =="

echo "-- naming / parsing"
[ "$(al_part_dev /dev/sda 1)"      = /dev/sda1      ] && ok "sda1"        || bad "sda1"
[ "$(al_part_dev /dev/nvme0n1 2)"  = /dev/nvme0n1p2 ] && ok "nvme0n1p2"   || bad "nvme0n1p2"
[ "$(al_part_dev /dev/mmcblk0 1)"  = /dev/mmcblk0p1 ] && ok "mmcblk0p1"   || bad "mmcblk0p1"
[ "$(al_part_dev /dev/loop3 1)"    = /dev/loop3p1   ] && ok "loop3p1"     || bad "loop3p1"
truncate -s 10M "$WORK/plain.img"; sgdisk -og "$WORK/plain.img" >/dev/null
[ "$(al_sector_size "$WORK/plain.img")" = 512 ] && ok "sector size (plain file)" || bad "sector size (plain file)"

echo "-- detection / refusals"
win_disk healthy;    D=$DISK; expect_ok     "healthy Windows disk is accepted" al_check "$D"
win_disk hibernated hibernated; D=$DISK; expect_refuse "hibernation/Fast Startup refused" "hibernat|fast startup" al_check "$D"
win_disk bitlocker bitlocker;  D=$DISK; expect_refuse "BitLocker refused" "bitlocker" al_check "$D"
win_disk dirty dirty;      D=$DISK; expect_refuse "dirty filesystem refused" "dirty|disk check|chkdsk" al_check "$D"
win_disk full full;  D=$DISK; expect_refuse "too-full disk refused" "not enough" al_check "$D"
mkdisk mbr 200; parted -s "$DISK" mklabel msdos; D=$DISK
expect_refuse "MBR disk refused" "not GPT" al_check "$D"
mkdisk blank 200; D=$DISK
expect_refuse "blank disk refused" "not GPT|No Windows" al_check "$D"

echo "-- apply + rollback"
win_disk rollback; D=$DISK; W=$(al_part_dev "$D" 2)
before=$(sgdisk -i 2 "$D")
AL_FORCE_FAIL=after_resize al_apply "$D" >/dev/null 2>&1 && bad "forced failure should fail" || ok "forced failure reported"
after=$(sgdisk -i 2 "$D")
[ "$before" = "$after" ] && ok "rollback restores Windows partition entry identically" || bad "rollback restores Windows partition entry identically"
[ "$(sgdisk -p "$D" | awk '/^ +[0-9]+ /{c++} END{print c}')" = 2 ] && ok "rollback leaves no extra partition" || bad "rollback leaves no extra partition"

win_disk apply; D=$DISK; before_first=$(sgdisk -i 2 "$D" | sed -n 's/^First sector: *\([0-9]*\).*/\1/p')
expect_ok "end-to-end apply() shrink" al_apply "$D"
[ "$(sgdisk -i 2 "$D" | sed -n 's/^First sector: *\([0-9]*\).*/\1/p')" = "$before_first" ] && ok "Windows start sector unchanged" || bad "Windows start sector unchanged"
[ -n "$AL_NEW_LINUX_NUM" ] && sgdisk -i "$AL_NEW_LINUX_NUM" "$D" | grep -q 'Teddy OS' && ok "Teddy OS partition created" || bad "Teddy OS partition created"

echo "-- strict mode (as used by install.sh) + interactive menu"
win_disk strict; D=$DISK
if ( set -euo pipefail; source "$HERE/../iso-builder/lib/alongside.sh"; source "$HERE/../iso-builder/lib/alongside-menu.sh"
     echo YES | alongside_menu "$D" >/dev/null 2>&1 ); then ok "alongside_menu works under set -euo pipefail"; else bad "alongside_menu works under set -euo pipefail"; fi
win_disk strict2; D=$DISK
if ( set -euo pipefail; source "$HERE/../iso-builder/lib/alongside.sh"; source "$HERE/../iso-builder/lib/alongside-menu.sh"
     echo no | alongside_menu "$D" >/dev/null 2>&1 ); then bad "menu cancel should return non-zero"; else
  [ "$(sgdisk -p "$D" | awk '/^ +[0-9]+ /{c++} END{print c}')" = 2 ] && ok "cancelling leaves the disk untouched" || bad "cancelling leaves the disk untouched"; fi

echo
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
