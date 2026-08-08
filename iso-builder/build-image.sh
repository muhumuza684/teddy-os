#!/bin/bash
# =================================================================
#  TEDDY OS Ã¢â‚¬â€ ISO Build System v1.0
#  Built by Bryt Ma Tech Uganda
#
#  Run on Ubuntu 22.04 or 24.04 (x86_64) with sudo
#  Output: teddyos-1.0.0-x86_64.iso
# =================================================================
set -euo pipefail

# Ã¢â€â‚¬Ã¢â€â‚¬ Config Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
TEDDY_VERSION="1.0.0"
TEDDY_CODENAME="Kampala"
TEDDY_ARCH="amd64"
DEBIAN_SUITE="bookworm"
DEBIAN_MIRROR="http://deb.debian.org/debian"

WORK="$(pwd)/work"
ROOTFS="$WORK/rootfs"
ISO="$WORK/iso"
OUTPUT="$(pwd)/teddyos-${TEDDY_VERSION}-x86_64.iso"

# Ã¢â€â‚¬Ã¢â€â‚¬ Colors Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' B='\033[1m' N='\033[0m'

step()    { echo -e "\n${B}${C}Ã¢â€ÂÃ¢â€ÂÃ¢â€Â $1 ${N}"; }
ok()      { echo -e "  ${G}Ã¢Å“â€œ${N} $1"; }
warn()    { echo -e "  ${Y}Ã¢Å¡Â ${N}  $1"; }
fail()    { echo -e "  ${R}Ã¢Å“â€”${N} $1"; exit 1; }
progress(){ echo -e "  ${C}Ã¢â€ â€™${N} $1"; }

# --- Restore rootfs and iso staging dir from previous job ---
step "Extracting rootfs and iso staging directory"
mkdir -p "$WORK"
tar -C "$WORK" --use-compress-program=unzstd -xf "$(pwd)/artifact/teddy-work.tar.zst"
ok "Restored work directory"

# Ã¢â€â‚¬Ã¢â€â‚¬ Squash filesystem Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
step "Compressing filesystem (5-15 min)"
df -h
progress "Creating squashfs with xz compression..."
mksquashfs "$ROOTFS" "$ISO/live/filesystem.squashfs" \
    -comp gzip \
    -b 1048576 \
    -noappend \
    -wildcards \
    -e boot 2>/dev/null
ok "Filesystem compressed: $(du -sh "$ISO/live/filesystem.squashfs" | cut -f1)"

# Ã¢â€â‚¬Ã¢â€â‚¬ Kernel + initrd Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
step "Copying kernel and initramfs"
KERNEL=$(ls "$ROOTFS/boot/vmlinuz-"* | head -1)
INITRD=$(ls "$ROOTFS/boot/initrd.img-"* | head -1)
cp "$KERNEL" "$ISO/live/vmlinuz"
cp "$INITRD" "$ISO/live/initrd.img"
ok "Kernel: $(basename "$KERNEL")"
ok "Initrd: $(basename "$INITRD")"

# Ã¢â€â‚¬Ã¢â€â‚¬ GRUB config Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
step "Writing bootloader configuration"

cat > "$ISO/boot/grub/grub.cfg" << GRUBCFG
# Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Teddy OS GRUB Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
# Built by Bryt Ma Tech Uganda

set default=0
set timeout=6
set timeout_style=menu
set gfxmode=auto
set gfxpayload=keep

insmod all_video
insmod gfxterm
insmod png
insmod jpeg
terminal_output gfxterm

# Colors
set color_normal=light-gray/black
set color_highlight=white/purple

menuentry "Ã°Å¸ÂÂ»  Boot Teddy OS ${TEDDY_VERSION}" --class teddy-os {
    linux  /live/vmlinuz \\
        boot=live \\
        quiet \\
        splash \\
        hostname=teddy-os \\
        username=teddy \\
        user-fullname="Teddy User" \\
        locales=en_US.UTF-8 \\
        timezone=Africa/Kampala \\
        keyboard-layouts=us \\
        components
    initrd /live/initrd.img
}

menuentry "Ã°Å¸â€Â§  Boot Teddy OS Ã¢â‚¬â€ Safe mode" --class teddy-os {
    linux  /live/vmlinuz \\
        boot=live \\
        nomodeset \\
        hostname=teddy-os \\
        username=teddy \\
        locales=en_US.UTF-8 \\
        components
    initrd /live/initrd.img
}

menuentry "Ã°Å¸â€™Â¿  Install Teddy OS to hard drive" --class install {
    linux  /live/vmlinuz \\
        boot=live \\
        components \\
        quiet \\
        hostname=teddy-os \\
        username=teddy
    initrd /live/initrd.img
}

menuentry "Ã°Å¸â€“Â¥  Boot from hard drive" --class harddisk {
    set root=(hd0)
    chainloader +1
}

menuentry "Ã°Å¸Â§Âª  Memory test (memtest86+)" --class memtest {
    linux /live/memtest
}
GRUBCFG

# BIOS GRUB
grub-mkimage \
    -d /usr/lib/grub/i386-pc \
    -O i386-pc \
    -o "$ISO/boot/grub/core.img" \
    -p /boot/grub \
    biosdisk iso9660 normal search search_fs_uuid \
    linux echo all_video gfxterm gfxterm_background \
    png jpeg font 2>/dev/null || warn "BIOS GRUB skipped"

# UEFI GRUB
if [ -d /usr/lib/grub/x86_64-efi ]; then
    grub-mkimage \
        -d /usr/lib/grub/x86_64-efi \
        -O x86_64-efi \
        -o "$ISO/EFI/boot/bootx64.efi" \
        -p /boot/grub \
        efifwsetup efi_gop efi_uga linuxefi \
        iso9660 normal search all_video echo font \
        gfxterm gfxterm_background png jpeg 2>/dev/null || warn "UEFI GRUB skipped"
    cp "$ISO/EFI/boot/bootx64.efi" "$ISO/EFI/boot/grubx64.efi" 2>/dev/null || true
fi

# Copy GRUB fonts
GRUB_FONTS="/usr/share/grub"
[ -d "$GRUB_FONTS/fonts" ] && cp -r "$GRUB_FONTS/fonts" "$ISO/boot/grub/" 2>/dev/null || true
[ -d "$GRUB_FONTS/themes" ] && cp -r "$GRUB_FONTS/themes" "$ISO/boot/grub/" 2>/dev/null || true

ok "Bootloader configured (BIOS + UEFI)"

# Ã¢â€â‚¬Ã¢â€â‚¬ Build ISO Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
step "Building ISO image"
progress "Running xorriso..."

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "TEDDYOS_10" \
    -appid "Teddy OS ${TEDDY_VERSION} Ã¢â‚¬â€ Bryt Ma Tech Uganda" \
    -publisher "Bryt Ma Tech Uganda" \
    -preparer "Teddy OS Build System" \
    -eltorito-boot boot/grub/core.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --eltorito-catalog boot/grub/boot.cat \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-alt-boot \
    -e EFI/boot/bootx64.efi \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    -o "$OUTPUT" \
    "$ISO" 2>&1 | grep -E "^(Total|Written|xorriso)" || true

ok "ISO built: $(du -sh "$OUTPUT" | cut -f1)"

# Ã¢â€â‚¬Ã¢â€â‚¬ Done Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
echo ""
echo -e "${B}${G}"
echo "  Ã¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€Â"
echo "  Ã°Å¸ÂÂ»  TEDDY OS ISO READY"
echo "  Ã¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€ÂÃ¢â€Â"
echo -e "${N}"
echo "  File : $OUTPUT"
echo "  Size : $(du -sh "$OUTPUT" | cut -f1)"
echo "  Built: $(date)"
echo ""
echo "  Ã¢â€â‚¬Ã¢â€â‚¬ Flash to USB Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬"
echo "  Linux/Mac:"
echo "    sudo dd if=$OUTPUT of=/dev/sdX bs=4M status=progress"
echo ""
echo "  Windows: Use balenaEtcher Ã¢â‚¬â€ https://etcher.balena.io"
echo ""
echo "  Ã¢â€â‚¬Ã¢â€â‚¬ Boot your laptop Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬"
echo "  Insert USB Ã¢â€ â€™ restart Ã¢â€ â€™ press F12 (or F8/F9/Esc)"
echo "  Select USB drive from boot menu"
echo ""
echo "  Ã¢â€â‚¬Ã¢â€â‚¬ Install permanently Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬"
echo "  Once booted: sudo bash /opt/teddy-os/install.sh"
echo ""
echo -e "  ${Y}Built by Bryt Ma Tech Uganda${N}"
echo ""

# NOTE: All branding is already embedded in the build script above.
# Key branding locations:
# - /etc/os-release          Ã¢â€ â€™ "Teddy OS" identity
# - /etc/teddy-os/release    Ã¢â€ â€™ Bryt Ma Tech Uganda
# - GRUB menu                Ã¢â€ â€™ Ã°Å¸ÂÂ» Teddy OS branding
# - Wallpaper SVG            Ã¢â€ â€™ "Built by Bryt Ma Tech Uganda"
# - Neofetch MOTD            Ã¢â€ â€™ Shows on every terminal open
# - ISO publisher field      Ã¢â€ â€™ "Bryt Ma Tech Uganda"
# - tint2 taskbar            Ã¢â€ â€™ Shows "Teddy OS" bottom bar
# - LightDM greeter          Ã¢â€ â€™ Custom dark login screen
