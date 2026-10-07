#!/bin/bash
# =================================================================
#  TEDDY OS â€” Hard Drive Installer v1.0
#  Run from inside the live Tedyt OS session
#  Built by Bryt Ma Tech Uganda
# =================================================================
set -euo pipefail

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' B='\033[1m' N='\033[0m'

step()    { echo -e "\n${B}${C}â”â”â” $1 ${N}"; }
ok()      { echo -e "  ${G}âœ“${N} $1"; }
warn()    { echo -e "  ${Y}âš ${N}  $1"; }
fail()    { echo -e "  ${R}âœ—${N} $1"; exit 1; }
progress(){ echo -e "  ${C}â†’${N} $1"; }

[[ $EUID -ne 0 ]] && fail "Run as root: sudo bash install.sh"

clear 2>/dev/null || true
echo -e "${B}${C}"
cat << 'EOF'
  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•—   â–ˆâ–ˆâ•—      â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—
     â–ˆâ–ˆâ•”â•â•â•â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â•šâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•”â•     â–ˆâ–ˆâ•”â•â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•”â•â•â•â•â•
     â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘ â•šâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•      â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—
     â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘  â•šâ–ˆâ–ˆâ•”â•       â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘â•šâ•â•â•â•â–ˆâ–ˆâ•‘
     â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•   â–ˆâ–ˆâ•‘        â•šâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘
     â•šâ•â•   â•šâ•â•â•â•â•â•â•â•šâ•â•â•â•â•â• â•šâ•â•â•â•â•â•    â•šâ•â•         â•šâ•â•â•â•â•â• â•šâ•â•â•â•â•â•â•
EOF
echo -e "${N}"
echo -e "  ${C}Teddy OS Installer v1.0${N}"
echo -e "  ${Y}Built by Bryt Ma Tech Uganda${N}"
echo ""
echo -e "  ${R}${B}WARNING: the default option erases the selected disk completely!${N}"
echo ""

# â”€â”€ Select disk â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Available storage devices"
echo ""
lsblk -d -o NAME,SIZE,MODEL,TYPE,TRAN | grep -v loop
echo ""

read -rp "  Enter disk to install on (e.g. sda, nvme0n1): " RAW_DISK
DISK="/dev/$RAW_DISK"
[[ ! -b "$DISK" ]] && fail "Disk $DISK not found. Check spelling."

DISK_SIZE=$(lsblk -d -o SIZE "$DISK" | tail -1 | tr -d ' ')

# Install mode: erase the disk, or (UEFI only) keep Windows and share the disk.
INSTALL_MODE="erase"
EFI_DIR="${TEDDY_EFI_DIR:-/sys/firmware/efi}"   # override only used by tests
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$EFI_DIR" ] && [ -f "$SCRIPT_DIR/lib/alongside.sh" ]; then
    echo ""
    echo "  How do you want to install?"
    echo "    1) Erase the whole disk (Teddy OS only)"
    echo "    2) Install alongside Windows (keeps Windows and your files)"
    read -rp "  Choose 1 or 2 [1]: " MODE_CHOICE
    [ "${MODE_CHOICE:-1}" = "2" ] && INSTALL_MODE="alongside"
fi

if [ "$INSTALL_MODE" = "erase" ]; then
    echo ""
    warn "TARGET DISK : $DISK ($DISK_SIZE)"
    warn "ALL DATA WILL BE PERMANENTLY ERASED"
    echo ""
    read -rp "  Type ERASE to confirm: " CONFIRM
    [[ "$CONFIRM" != "ERASE" ]] && { echo "Aborted."; exit 0; }
fi

# â”€â”€ UEFI or BIOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Detecting boot mode"
if [ -d "$EFI_DIR" ]; then
    MODE="uefi"
    ok "UEFI mode detected"
else
    MODE="bios"
    ok "Legacy BIOS mode detected"
fi

# â”€â”€ Partition naming helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
part() {
    # Any disk name ending in a digit (nvme0n1, mmcblk0, loop0, md0...) needs a 'p' separator.
    case "$DISK" in
        *[0-9]) echo "${DISK}p${1}" ;;
        *)      echo "${DISK}${1}" ;;
    esac
}

# â”€â”€ Partitioning â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
SWAP_PART=""
if [ "$INSTALL_MODE" = "alongside" ]; then
    step "Installing alongside Windows"
    # shellcheck source=lib/alongside.sh
    source "$SCRIPT_DIR/lib/alongside.sh"
    # shellcheck source=lib/alongside-menu.sh
    source "$SCRIPT_DIR/lib/alongside-menu.sh"
    alongside_menu "$DISK" || fail "Alongside install stopped: ${AL_REASON:-cancelled}. Nothing was left changed."
    EFI_PART="$AL_ESP_PART"                                   # reuse Windows' ESP - never reformat it
    ROOT_PART="$(al_part_dev "$DISK" "$AL_NEW_LINUX_NUM")"
    sleep 2; partprobe "$DISK" 2>/dev/null || true; sleep 1
    [ -b "$ROOT_PART" ] || fail "New partition $ROOT_PART did not appear."
    ok "Teddy OS partition: $ROOT_PART   (Windows ESP reused: $EFI_PART)"
else
step "Partitioning $DISK"
progress "Wiping existing partition table..."
wipefs -a "$DISK"
dd if=/dev/zero of="$DISK" bs=1M count=10 2>/dev/null

if [ "$MODE" = "uefi" ]; then
    progress "Creating GPT partition table (UEFI)..."
    parted -s "$DISK" \
        mklabel gpt \
        mkpart "EFI"  fat32  1MiB    513MiB \
        set 1 esp on \
        mkpart "SWAP" linux-swap 513MiB 2561MiB \
        mkpart "ROOT" ext4  2561MiB 100%
    EFI_PART=$(part 1)
    SWAP_PART=$(part 2)
    ROOT_PART=$(part 3)
else
    progress "Creating MBR partition table (BIOS)..."
    parted -s "$DISK" \
        mklabel msdos \
        mkpart primary linux-swap 1MiB    2049MiB \
        mkpart primary ext4       2049MiB 100% \
        set 2 boot on
    SWAP_PART=$(part 1)
    ROOT_PART=$(part 2)
fi

# Wait for kernel to register new partitions
sleep 2
partprobe "$DISK" 2>/dev/null || true
sleep 1
ok "Partitioned"
fi

# â”€â”€ Format â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Formatting partitions"

if [ "$MODE" = "uefi" ] && [ "$INSTALL_MODE" = "erase" ]; then
    mkfs.fat -F32 -n "TEDDY_EFI" "$EFI_PART"
    ok "EFI: $EFI_PART (FAT32)"
fi

if [ -n "$SWAP_PART" ]; then
    mkswap -L "teddy-swap" "$SWAP_PART"
    ok "Swap: $SWAP_PART"
fi

mkfs.ext4 -L "teddy-root" -F -m 1 "$ROOT_PART"
ok "Root: $ROOT_PART (ext4)"

# â”€â”€ Mount â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Mounting target"
MOUNT="/mnt/teddy"
mkdir -p "$MOUNT"
mount "$ROOT_PART" "$MOUNT"

if [ "$MODE" = "uefi" ]; then
    mkdir -p "$MOUNT/boot/efi"
    mount "$EFI_PART" "$MOUNT/boot/efi"
fi

[ -n "$SWAP_PART" ] && swapon "$SWAP_PART"
ok "Mounted at $MOUNT"

# â”€â”€ Copy system â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Installing Teddy OS (this takes 5-20 minutes)"
progress "Copying files to $ROOT_PART..."

rsync -aAXH \
    --info=progress2 \
    --exclude=/proc \
    --exclude=/sys \
    --exclude=/dev \
    --exclude=/run \
    --exclude=/mnt \
    --exclude=/media \
    --exclude=/tmp \
    --exclude=/lost+found \
    --exclude=/live \
    --exclude=/cdrom \
    / "$MOUNT/"

ok "Files copied"

# â”€â”€ Essential dirs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
mkdir -p "$MOUNT"/{proc,sys,dev,run,tmp,mnt,media,cdrom}
chmod 1777 "$MOUNT/tmp"

# â”€â”€ fstab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Writing system configuration"

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
SWAP_UUID=""
[ -n "$SWAP_PART" ] && SWAP_UUID=$(blkid -s UUID -o value "$SWAP_PART")

cat > "$MOUNT/etc/fstab" << FSTAB
# /etc/fstab â€” Teddy OS
# Generated by Teddy OS Installer
# Built by Bryt Ma Tech Uganda
#
# <device>      <mount>    <type>  <options>           <dump>  <fsck>
UUID=$ROOT_UUID /          ext4    errors=remount-ro   0       1
tmpfs           /tmp       tmpfs   defaults,nosuid     0       0
FSTAB

if [ -n "$SWAP_UUID" ]; then
    echo "UUID=$SWAP_UUID none       swap    sw                  0       0" >> "$MOUNT/etc/fstab"
elif [ "$INSTALL_MODE" = "alongside" ]; then
    # no swap partition when sharing a disk with Windows: use a swap file instead
    fallocate -l 2G "$MOUNT/swapfile" && chmod 600 "$MOUNT/swapfile" && mkswap "$MOUNT/swapfile" >/dev/null \
        && echo "/swapfile none swap sw 0 0" >> "$MOUNT/etc/fstab"
fi

if [ "$MODE" = "uefi" ]; then
    EFI_UUID=$(blkid -s UUID -o value "$EFI_PART")
    echo "UUID=$EFI_UUID  /boot/efi  vfat  umask=0077  0  2" >> "$MOUNT/etc/fstab"
fi
ok "fstab written"

# â”€â”€ Chroot setup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Configuring bootloader"

# Bind mounts for chroot
for fs in dev dev/pts proc sys run; do
    mount --bind "/$fs" "$MOUNT/$fs" 2>/dev/null || true
done

cleanup_chroot() {
    for fs in dev/pts dev proc sys run; do
        umount -lf "$MOUNT/$fs" 2>/dev/null || true
    done
}
trap cleanup_chroot EXIT

# Remove live-boot, install grub
chroot "$MOUNT" bash -c "
    export DEBIAN_FRONTEND=noninteractive
    # Remove live-boot packages
    apt-get remove -y --purge live-boot live-boot-initramfs-tools live-config 2>/dev/null || true

    # Update initramfs for real hardware
    update-initramfs -u -k all

    # Write GRUB defaults
    cat > /etc/default/grub << 'GRUBDEF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=\"Teddy OS\"
GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"
GRUB_CMDLINE_LINUX=\"\"
GRUB_GFXMODE=\"1920x1080,1366x768,auto\"
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_OS_PROBER=false
GRUB_BACKGROUND=\"/usr/share/backgrounds/teddy-os/default.svg\"
GRUBDEF

    # Install GRUB
    if [ -d /sys/firmware/efi ]; then
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=TeddyOS --recheck
    else
        grub-install --target=i386-pc --recheck $DISK
    fi

    update-grub

    # Remove autologin for installed system (require password)
    cat > /etc/lightdm/lightdm.conf << 'LDM'
[LightDM]
run-directory=/run/lightdm
minimum-vt=7

[Seat:*]
user-session=openbox
greeter-session=lightdm-gtk-greeter
xserver-command=X -nolisten tcp -dpi 96
LDM
"

ok "Bootloader installed"

# â”€â”€ Unmount â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Finalizing"
cleanup_chroot
trap - EXIT

if [ "$MODE" = "uefi" ]; then
    umount "$MOUNT/boot/efi"
fi
umount "$MOUNT"
[ -n "$SWAP_PART" ] && swapoff "$SWAP_PART" || true

# â”€â”€ Done â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo ""
echo -e "${B}${G}"
echo "  â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "  ðŸ»  TEDDY OS INSTALLED SUCCESSFULLY!"
echo "  â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo -e "${N}"
echo "  Installed to : $DISK"
echo "  Boot mode    : $MODE"
echo "  Root         : $ROOT_PART"
echo ""
echo "  Default login: teddy / teddy"
echo "  Change it!   : passwd (after first login)"
echo ""
echo "  â”€â”€â”€ Next steps â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€"
echo "  1. Remove the USB drive"
echo "  2. sudo reboot"
echo "  3. Boot into Teddy OS from your hard drive"
echo ""
echo -e "  ${Y}Built by Bryt Ma Tech Uganda${N}"
echo ""
