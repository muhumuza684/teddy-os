#!/usr/bin/env bash
# Teddy OS - "install alongside Windows" safety library.
#
# SOURCE this file; do not execute it.
#   source iso-builder/lib/alongside.sh
#   al_check /dev/sda   || echo "Refused: $AL_REASON"
#   al_apply /dev/sda   || echo "Failed + rolled back: $AL_REASON"
#
# Every function returns 0 on success, non-zero on failure/refusal.
# On failure, AL_REASON holds a specific human-readable reason.
#
# Tunables (environment):
#   AL_MIN_LINUX_MIB      minimum space to free for Teddy OS     (default 20480)
#   AL_WIN_HEADROOM_MIB   free space left inside Windows         (default 5120)
#   AL_BACKUP_DIR         where GPT backups are kept             (default /var/tmp/teddy-alongside)
#   AL_FORCE_FAIL         test hook: "after_resize" forces a failure after the
#                         partition table was rewritten, to exercise rollback

AL_REASON=""
AL_BACKUP_DIR="${AL_BACKUP_DIR:-/var/tmp/teddy-alongside}"
AL_MIN_LINUX_MIB="${AL_MIN_LINUX_MIB:-20480}"
AL_WIN_HEADROOM_MIB="${AL_WIN_HEADROOM_MIB:-5120}"

# Results populated by al_detect_windows / al_plan
AL_WIN_NUM=""; AL_WIN_PART=""; AL_ESP_PART=""
AL_NEW_NTFS_BYTES=""; AL_FREED_BYTES=""
AL_BACKUP_FILE=""
AL_NEW_LINUX_NUM=""

readonly AL_ESP_GUID="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
readonly AL_MIB=1048576

al_log()  { echo "[alongside] $*" >&2; }
al_fail() { AL_REASON="$*"; al_log "REFUSE/FAIL: $*"; return 1; }

# ---------------------------------------------------------------------------
# Device naming.  /dev/sda -> sda1 ; but anything whose name ends in a digit
# (nvme0n1, mmcblk0, loop0, md0 ...) needs a 'p' separator.
# ---------------------------------------------------------------------------
al_part_dev() {
  local disk="$1" num="$2"
  case "$disk" in
    *[0-9]) echo "${disk}p${num}" ;;
    *)      echo "${disk}${num}" ;;
  esac
}

# ---------------------------------------------------------------------------
# Logical sector size.  Prefer the kernel's answer (block devices); fall back to
# parsing sgdisk, accepting BOTH output shapes:
#   plain file : "Sector size (logical): 512 bytes"
#   block dev  : "Sector size (logical/physical): 512/512 bytes"
# ---------------------------------------------------------------------------
al_sector_size() {
  local disk="$1" s
  s=$(blockdev --getss "$disk" 2>/dev/null)
  if [ -z "$s" ]; then
    s=$(sgdisk -p "$disk" 2>/dev/null \
        | sed -n 's/^Sector size (logical[^)]*): *\([0-9][0-9]*\).*/\1/p' | head -1)
  fi
  echo "${s:-512}"
}

al_refresh() {  # re-read the partition table and wait for device nodes
  local disk="$1"
  sync
  partprobe "$disk" >/dev/null 2>&1 || partx -u "$disk" >/dev/null 2>&1
  command -v udevadm >/dev/null 2>&1 && udevadm settle --timeout=10 >/dev/null 2>&1
  sleep 1
}

al_part_numbers() {  # list partition numbers on a GPT disk
  sgdisk -p "$1" 2>/dev/null | awk '/^ +[0-9]+ +[0-9]+ /{print $1}'
}

# field extraction from `sgdisk -i`
al_pinfo() {  # disk num field
  local disk="$1" num="$2" field="$3"
  sgdisk -i "$num" "$disk" 2>/dev/null | case "$field" in
    typeguid) sed -n 's/^Partition GUID code: *\([0-9A-Fa-f-]*\).*/\1/p' ;;
    uniqguid) sed -n 's/^Partition unique GUID: *\([0-9A-Fa-f-]*\).*/\1/p' ;;
    first)    sed -n 's/^First sector: *\([0-9]*\).*/\1/p' ;;
    last)     sed -n 's/^Last sector: *\([0-9]*\).*/\1/p' ;;
    name)     sed -n "s/^Partition name: *'\(.*\)'.*/\1/p" ;;
    attrs)    sed -n 's/^Attribute flags: *\([0-9A-Fa-f]*\).*/\1/p' ;;
  esac
}

al_is_gpt() {
  [ "$(blkid -p -o value -s PTTYPE "$1" 2>/dev/null)" = "gpt" ]
}

al_unmount_disk() {
  local disk="$1" n dev
  for n in $(al_part_numbers "$disk"); do
    dev=$(al_part_dev "$disk" "$n")
    mountpoint -q "$dev" 2>/dev/null && umount "$dev" 2>/dev/null
    grep -q "^$dev " /proc/mounts 2>/dev/null && umount "$dev" 2>/dev/null
  done
  return 0
}

# ---------------------------------------------------------------------------
# Windows detection: an ESP carrying the Windows boot manager AND an NTFS
# partition carrying \Windows\System32.
# ---------------------------------------------------------------------------
al_has_file_ro() {  # dev fstype path...   (mounted read-only, always cleaned up)
  local dev="$1" fs="$2"; shift 2
  local mnt found=1 p
  mnt=$(mktemp -d) || return 1
  if mount -t "$fs" -o ro "$dev" "$mnt" 2>/dev/null; then
    for p in "$@"; do
      [ -e "$mnt/$p" ] && { found=0; break; }
    done
    umount "$mnt" 2>/dev/null
  fi
  rmdir "$mnt" 2>/dev/null
  return $found
}

al_detect_windows() {
  local disk="$1" n dev tg fs
  AL_WIN_NUM=""; AL_WIN_PART=""; AL_ESP_PART=""
  for n in $(al_part_numbers "$disk"); do
    dev=$(al_part_dev "$disk" "$n")
    [ -b "$dev" ] || continue
    tg=$(al_pinfo "$disk" "$n" typeguid)
    fs=$(blkid -p -o value -s TYPE "$dev" 2>/dev/null)
    if [ "${tg^^}" = "$AL_ESP_GUID" ] && [ -z "$AL_ESP_PART" ]; then
      if al_has_file_ro "$dev" vfat EFI/Microsoft/Boot/bootmgfw.efi \
         || { command -v mdir >/dev/null 2>&1 && mdir -i "$dev" ::/EFI/Microsoft/Boot/bootmgfw.efi >/dev/null 2>&1; }; then
        AL_ESP_PART="$dev"   # (mtools fallback works where the kernel has no vfat driver)
      fi
    elif [ "$fs" = "ntfs" ] && [ -z "$AL_WIN_PART" ]; then
      if al_has_file_ro "$dev" ntfs-3g Windows/System32 Windows/system32; then
        AL_WIN_PART="$dev"; AL_WIN_NUM="$n"
      fi
    elif [ "$fs" = "BitLocker" ] && [ -z "$AL_WIN_PART" ]; then
      AL_WIN_PART="$dev"; AL_WIN_NUM="$n"   # cannot look inside; al_check refuses
    fi
  done
  [ -n "$AL_WIN_PART" ] && [ -n "$AL_ESP_PART" ]
}

# ---------------------------------------------------------------------------
# Individual safety checks.
# ---------------------------------------------------------------------------
al_is_bitlocker() {
  local dev="$1"
  [ "$(blkid -p -o value -s TYPE "$dev" 2>/dev/null)" = "BitLocker" ] && return 0
  [ "$(dd if="$dev" bs=1 skip=3 count=8 2>/dev/null)" = "-FVE-FS-" ]
}

# Returns 0 if safe to resize; otherwise sets AL_REASON and returns 1.
al_check_ntfs_state() {
  local dev="$1" rc
  ntfs-3g.probe --readwrite "$dev" >/dev/null 2>&1
  rc=$?
  case $rc in
    0)  # probe does not see the "check at next boot" flag; ntfsresize (no --force) does
        if ntfsresize --info --no-progress-bar "$dev" 2>&1 | grep -qi 'scheduled for check\|dirty\|inconsistent'; then
          al_fail "The Windows disk is flagged dirty / needs a disk check. Boot Windows and run 'chkdsk C: /f', shut down fully, then try again."
          return 1
        fi
        return 0 ;;
    4|14) al_fail "Windows is hibernated or has Fast Startup enabled. Boot Windows, run 'shutdown /s /f /t 0' (a real shutdown, not Restart) and disable Fast Startup, then try again." ;;
    5|6) al_fail "The Windows disk is flagged dirty / needs a disk check. Boot Windows and run 'chkdsk C: /f', shut down fully, then try again." ;;
    *) al_fail "The Windows partition cannot be opened safely for writing (ntfs-3g.probe code $rc). Run chkdsk in Windows first." ;;
  esac
}

# Work out how much can be freed.  Sets AL_NEW_NTFS_BYTES / AL_FREED_BYTES.
al_plan() {
  local disk="$1" dev="$AL_WIN_PART" info min cur ss new
  info=$(ntfsresize --info --force --no-progress-bar "$dev" 2>&1)
  min=$(echo "$info" | sed -n 's/^You might resize at \([0-9][0-9]*\) bytes.*/\1/p' | head -1)
  [ -n "$min" ] || { al_fail "Could not determine how small the Windows volume can safely become."; return 1; }
  ss=$(al_sector_size "$disk")
  cur=$(( ( $(al_pinfo "$disk" "$AL_WIN_NUM" last) - $(al_pinfo "$disk" "$AL_WIN_NUM" first) + 1 ) * ss ))
  new=$(( min + AL_WIN_HEADROOM_MIB * AL_MIB ))
  new=$(( ( (new + AL_MIB - 1) / AL_MIB ) * AL_MIB ))          # round up to 1 MiB
  AL_NEW_NTFS_BYTES=$new
  AL_FREED_BYTES=$(( cur - new ))
  if [ "$AL_FREED_BYTES" -lt $(( AL_MIN_LINUX_MIB * AL_MIB )) ]; then
    al_fail "Not enough freeable space: Windows can only give up $(( AL_FREED_BYTES > 0 ? AL_FREED_BYTES / AL_MIB : 0 )) MiB, Teddy OS needs at least ${AL_MIN_LINUX_MIB} MiB. Free up space in Windows or choose another install mode."
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# al_check DISK : run every safety check, change NOTHING on disk.
# ---------------------------------------------------------------------------
al_check() {
  local disk="$1"
  AL_REASON=""
  [ -b "$disk" ] || { al_fail "$disk is not a block device."; return 1; }
  al_is_gpt "$disk" || { al_fail "Disk is not GPT (UEFI). Installing alongside Windows is only supported on GPT disks."; return 1; }
  al_unmount_disk "$disk"
  al_detect_windows "$disk" || { al_fail "No Windows installation (EFI boot files + NTFS system partition) found on $disk."; return 1; }
  al_is_bitlocker "$AL_WIN_PART" && { al_fail "Windows is encrypted with BitLocker. Suspend/decrypt BitLocker in Windows first - resizing an encrypted volume is not possible."; return 1; }
  al_check_ntfs_state "$AL_WIN_PART" || return 1
  al_plan "$disk" || return 1
  al_log "OK: Windows on $AL_WIN_PART, can free $(( AL_FREED_BYTES / AL_MIB )) MiB"
  return 0
}

# ---------------------------------------------------------------------------
# Verification (run after the shrink).
#   NOTE: ntfsresize deliberately flags the volume "check at next boot".  That is
#   normal and expected, and it makes ntfsls/ntfs-3g refuse to browse it - so we
#   verify with blkid, which does not fight that state.
# ---------------------------------------------------------------------------
al_verify() {
  local disk="$1" orig_uniq="$2" orig_first="$3" dev fs
  dev=$(al_part_dev "$disk" "$AL_WIN_NUM")
  [ -b "$dev" ] || { al_fail "Verification: Windows partition node $dev is missing."; return 1; }
  fs=$(blkid -p -o value -s TYPE "$dev" 2>/dev/null)
  [ "$fs" = "ntfs" ] || { al_fail "Verification: Windows partition no longer reports as ntfs (got '${fs:-nothing}')."; return 1; }
  [ "$(al_pinfo "$disk" "$AL_WIN_NUM" uniqguid)" = "$orig_uniq" ] || { al_fail "Verification: Windows partition GUID changed."; return 1; }
  [ "$(al_pinfo "$disk" "$AL_WIN_NUM" first)" = "$orig_first" ] || { al_fail "Verification: Windows partition start moved."; return 1; }
  sgdisk -v "$disk" 2>&1 | grep -q 'No problems found' || { al_fail "Verification: partition table has problems."; return 1; }
  return 0
}

# ---------------------------------------------------------------------------
# Rollback: restore the GPT exactly as it was before we touched anything.
# (If only the NTFS filesystem was shrunk but the table is unchanged, Windows
# still boots - a filesystem smaller than its partition is valid.)
# ---------------------------------------------------------------------------
al_rollback() {
  local disk="$1"
  [ -f "$AL_BACKUP_FILE" ] || { al_log "No backup to restore!"; return 1; }
  al_log "Rolling back partition table from $AL_BACKUP_FILE"
  sgdisk --load-backup="$AL_BACKUP_FILE" "$disk" >/dev/null 2>&1 || { al_log "ROLLBACK FAILED - backup kept at $AL_BACKUP_FILE"; return 1; }
  al_refresh "$disk"
  return 0
}

# ---------------------------------------------------------------------------
# al_apply DISK : shrink Windows and carve out a Linux partition.  Any failure
# restores the original partition table.  Sets AL_NEW_LINUX_NUM on success.
# ---------------------------------------------------------------------------
al_apply() {
  local disk="$1" ss first last uniq tguid name attrs new_part_sectors new_last
  local lin_start lin_end next usable_end n f
  al_check "$disk" || return 1

  ss=$(al_sector_size "$disk")
  first=$(al_pinfo "$disk" "$AL_WIN_NUM" first)
  last=$(al_pinfo "$disk" "$AL_WIN_NUM" last)
  uniq=$(al_pinfo "$disk" "$AL_WIN_NUM" uniqguid)
  tguid=$(al_pinfo "$disk" "$AL_WIN_NUM" typeguid)
  name=$(al_pinfo "$disk" "$AL_WIN_NUM" name)
  attrs=$(al_pinfo "$disk" "$AL_WIN_NUM" attrs)

  # 1. Back up the GPT before touching anything.
  mkdir -p "$AL_BACKUP_DIR" || { al_fail "Cannot create backup directory $AL_BACKUP_DIR."; return 1; }
  AL_BACKUP_FILE="$AL_BACKUP_DIR/gpt-$(basename "$disk")-$(date +%Y%m%d-%H%M%S).bak"
  sgdisk --backup="$AL_BACKUP_FILE" "$disk" >/dev/null 2>&1 && [ -s "$AL_BACKUP_FILE" ] \
    || { al_fail "Could not back up the partition table - nothing was changed."; return 1; }
  al_log "GPT backed up to $AL_BACKUP_FILE"

  al_unmount_disk "$disk"

  # 2. Shrink the NTFS filesystem (data is moved by ntfsresize).
  al_log "Shrinking NTFS on $AL_WIN_PART to $AL_NEW_NTFS_BYTES bytes"
  if ! ntfsresize --force --no-progress-bar --size "$AL_NEW_NTFS_BYTES" "$AL_WIN_PART" >/tmp/al-ntfsresize.log 2>&1; then
    al_fail "ntfsresize failed (log: /tmp/al-ntfsresize.log). Windows was not modified."
    al_rollback "$disk"; return 1
  fi

  # 3. Shrink the partition entry to match (same start, same GUIDs/name/attrs).
  new_part_sectors=$(( AL_NEW_NTFS_BYTES / ss ))
  new_last=$(( first + new_part_sectors - 1 ))
  if ! sgdisk -d "$AL_WIN_NUM" "$disk" >/dev/null 2>&1 \
     || ! sgdisk -n "$AL_WIN_NUM:$first:$new_last" -t "$AL_WIN_NUM:$tguid" -u "$AL_WIN_NUM:$uniq" \
                 -c "$AL_WIN_NUM:$name" "$disk" >/dev/null 2>&1; then
    al_fail "Could not rewrite the Windows partition entry."; al_rollback "$disk"; return 1
  fi
  if [ -n "$attrs" ] && [ "$attrs" != "0000000000000000" ]; then
    # restore e.g. "required partition"/"no drive letter" bits when present
    for f in 0 1 2 60 62 63; do
      [ $(( 0x$attrs >> f & 1 )) -eq 1 ] && sgdisk -A "$AL_WIN_NUM:set:$f" "$disk" >/dev/null 2>&1
    done
  fi

  # 4. Create the Linux partition in the space right after Windows.
  next=""; usable_end=$(sgdisk -p "$disk" | sed -n 's/.*last usable sector is \([0-9]*\).*/\1/p')
  for n in $(al_part_numbers "$disk"); do
    f=$(al_pinfo "$disk" "$n" first)
    [ "$f" -gt "$new_last" ] && { [ -z "$next" ] || [ "$f" -lt "$next" ]; } && next=$f
  done
  lin_start=$(( ( (new_last + 1 + 2047) / 2048 ) * 2048 ))        # 1 MiB aligned
  lin_end=$(( ${next:-$(( usable_end + 1 ))} - 1 ))
  if [ "$lin_end" -le "$lin_start" ]; then
    al_fail "No room found for the Teddy OS partition after shrinking."; al_rollback "$disk"; return 1
  fi
  AL_NEW_LINUX_NUM=$(( $(al_part_numbers "$disk" | sort -n | tail -1) + 1 ))
  if ! sgdisk -n "$AL_NEW_LINUX_NUM:$lin_start:$lin_end" -t "$AL_NEW_LINUX_NUM:8300" \
              -c "$AL_NEW_LINUX_NUM:Teddy OS" "$disk" >/dev/null 2>&1; then
    al_fail "Could not create the Teddy OS partition."; al_rollback "$disk"; return 1
  fi
  al_refresh "$disk"

  # test hook: prove rollback restores Windows' entry byte-for-byte
  if [ "${AL_FORCE_FAIL:-}" = "after_resize" ]; then
    al_fail "Forced failure (test hook)."; al_rollback "$disk"; return 1
  fi

  # 5. Verify; roll back if anything looks wrong.
  if ! al_verify "$disk" "$uniq" "$first"; then
    al_rollback "$disk"; return 1
  fi
  al_log "Done: Windows partition $AL_WIN_NUM shrunk, Teddy OS partition is #$AL_NEW_LINUX_NUM"
  return 0
}
