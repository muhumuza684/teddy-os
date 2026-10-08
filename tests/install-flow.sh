#!/usr/bin/env bash
# Drives the REAL iso-builder/install.sh end to end against scratch loop disks.
# Real: sgdisk, ntfsresize, mkfs.ext4, blkid, parted, wipefs.   Faked (logged): rsync, chroot, mount/umount, swapon/off,
# mkfs.fat, mkswap, fallocate, update-initramfs.  Run as root.
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$HERE/.."
export AL_TEST_LIB_ONLY=1
source "$ROOT/tools/test-alongside.sh"      # scratch-disk helpers (win_disk, mkdisk, ok/bad, cleanup trap)
unset AL_TEST_LIB_ONLY
export AL_MIN_LINUX_MIB=100 AL_WIN_HEADROOM_MIB=20

FAKE="$WORK/fakebin"; LOG="$WORK/calls.log"; export LOG_FILE="$LOG"; mkdir -p "$FAKE" /mnt/teddy
REALMOUNT=$(command -v mount); REALUMOUNT=$(command -v umount)
for c in rsync chroot swapon swapoff mkfs.fat update-initramfs; do
cat > "$FAKE/$c" <<SH
#!/bin/sh
echo "$c \$*" >> "$LOG"
[ "$c" = rsync ] && mkdir -p /mnt/teddy/etc
exit 0
SH
chmod +x "$FAKE/$c"; done
REALMKSWAP=$(command -v mkswap)
cat > "$FAKE/mkswap" <<SH
#!/bin/sh
echo "mkswap \$*" >> "$LOG"
for last; do :; done
[ -b "\$last" ] && exec $REALMKSWAP "\$@"   # real swap signature on real partitions, no-op for the fake swapfile
exit 0
SH
chmod +x "$FAKE/mkswap"
cat > "$FAKE/fallocate" <<'SH'
#!/bin/sh
echo "fallocate $*" >> "$LOG_FILE"
for last; do :; done; : > "$last"
exit 0
SH
chmod +x "$FAKE/fallocate"
# mount/umount: fake only the installer's own /mnt/teddy work; the safety library's real read-only probes pass through
for pair in "mount:$REALMOUNT" "umount:$REALUMOUNT"; do c=${pair%%:*}; real=${pair#*:}
cat > "$FAKE/$c" <<SH
#!/bin/sh
case "\$*" in *"/mnt/teddy"*|*--bind*) echo "$c \$*" >> "$LOG"; exit 0;; esac
exec $real "\$@"
SH
chmod +x "$FAKE/$c"; done

run_install() {   # disk-name  stdin-text
  : > "$LOG"; rm -rf /mnt/teddy/*
  PATH="$FAKE:$PATH" TEDDY_EFI_DIR=/tmp bash "$ROOT/iso-builder/install.sh" <<<"$1"$'\n'"$2" >"$WORK/install.out" 2>&1
}
nparts() { sgdisk -p "$1" | awk '/^ +[0-9]+ /{c++} END{print c+0}'; }

echo "== install.sh end-to-end =="
echo "-- alongside Windows"
win_disk flow; D=$DISK; N=$(basename "$D")
first_before=$(sgdisk -i 2 "$D" | sed -n 's/^First sector: *\([0-9]*\).*/\1/p')
run_install "$N" $'2\nYES' ; rc=$?
[ $rc -eq 0 ] && ok "installer exits 0" || { bad "installer exits 0" "rc=$rc"; tail -15 "$WORK/install.out"; }
[ "$(nparts "$D")" = 3 ] && ok "Windows + ESP kept, one Teddy partition added" || bad "partition count" "$(nparts "$D")"
[ "$(sgdisk -i 2 "$D" | sed -n 's/^First sector: *\([0-9]*\).*/\1/p')" = "$first_before" ] && ok "Windows partition start unchanged" || bad "Windows partition start unchanged"
[ "$(blkid -p -o value -s TYPE "$(al_part_dev "$D" 2)")" = ntfs ] && ok "Windows partition still ntfs" || bad "Windows partition still ntfs"
[ "$(blkid -p -o value -s TYPE "$(al_part_dev "$D" 3)")" = ext4 ] && ok "Teddy root formatted ext4" || bad "Teddy root formatted ext4"
mdir -i "$(al_part_dev "$D" 1)" ::/EFI/Microsoft/Boot/bootmgfw.efi >/dev/null 2>&1 && ok "Windows boot files still on the ESP" || bad "Windows boot files still on the ESP"
grep -q '^mkfs.fat' "$LOG" && bad "ESP must NOT be reformatted" || ok "ESP was not reformatted"
grep -q '^mkfs.fat\|swapon /dev' "$LOG" && bad "no swap partition expected" || ok "no swap partition created"
grep -q 'swapfile' /mnt/teddy/etc/fstab 2>/dev/null && ok "fstab uses a swap file" || bad "fstab uses a swap file"
grep -q 'ext4' /mnt/teddy/etc/fstab && grep -q 'vfat' /mnt/teddy/etc/fstab && ok "fstab has root + ESP entries" || bad "fstab has root + ESP entries"
grep -q 'DISABLE_OS_PROBER=false' "$ROOT/iso-builder/install.sh" && ok "GRUB os-prober enabled so Windows is in the boot menu" || bad "os-prober enabled"

echo "-- alongside refused (hibernated Windows)"
win_disk hib hibernated; D=$DISK; N=$(basename "$D"); before=$(sgdisk -p "$D")
run_install "$N" $'2\nYES'; rc=$?
[ $rc -ne 0 ] && ok "installer stops" || bad "installer stops"
grep -qi 'hibernat\|fast startup' "$WORK/install.out" && ok "tells the user why" || bad "tells the user why"
[ "$before" = "$(sgdisk -p "$D")" ] && ok "disk untouched after refusal" || bad "disk untouched after refusal"
grep -q '^rsync' "$LOG" && bad "must not copy files after refusal" || ok "no files copied after refusal"

echo "-- erase whole disk (original behaviour)"
mkdisk erase 3200; D=$DISK; N=$(basename "$D")
run_install "$N" $'1\nERASE'; rc=$?
[ $rc -eq 0 ] && ok "installer exits 0" || { bad "installer exits 0" "rc=$rc"; tail -15 "$WORK/install.out"; }
[ "$(nparts "$D")" = 3 ] && ok "EFI + swap + root created" || bad "EFI + swap + root" "$(nparts "$D")"
grep -q '^mkfs.fat' "$LOG" && ok "ESP formatted in erase mode" || bad "ESP formatted in erase mode"
grep -q '^mkswap' "$LOG" && grep -q ' swap ' /mnt/teddy/etc/fstab && ok "swap partition + fstab entry" || bad "swap partition + fstab entry"
run_install "$N" $'1\nno'; rc=$?
[ $rc -eq 0 ] && grep -q Aborted "$WORK/install.out" && ok "wrong confirmation aborts" || bad "wrong confirmation aborts"

rm -rf /mnt/teddy/*
echo; echo "Result: $PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]
