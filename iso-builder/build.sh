#!/bin/bash
# =================================================================
#  TEDDY OS â€” ISO Build System v1.0
#  Built by Bryt Ma Tech Uganda
#
#  Run on Ubuntu 22.04 or 24.04 (x86_64) with sudo
#  Output: teddyos-1.0.0-x86_64.iso
# =================================================================
set -euo pipefail

# â”€â”€ Config â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
TEDDY_VERSION="1.0.0"
TEDDY_CODENAME="Kampala"
TEDDY_ARCH="amd64"
DEBIAN_SUITE="bookworm"
DEBIAN_MIRROR="http://deb.debian.org/debian"

WORK="$(pwd)/work"
ROOTFS="$WORK/rootfs"
ISO="$WORK/iso"
OUTPUT="$(pwd)/teddyos-${TEDDY_VERSION}-x86_64.iso"

# â”€â”€ Colors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' B='\033[1m' N='\033[0m'

step()    { echo -e "\n${B}${C}â”â”â” $1 ${N}"; }
ok()      { echo -e "  ${G}âœ“${N} $1"; }
warn()    { echo -e "  ${Y}âš ${N}  $1"; }
fail()    { echo -e "  ${R}âœ—${N} $1"; exit 1; }
progress(){ echo -e "  ${C}â†’${N} $1"; }

# â”€â”€ Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
echo -e "  ${C}Teddy OS ${TEDDY_VERSION} \"${TEDDY_CODENAME}\" â€” ISO Builder${N}"
echo -e "  ${Y}Built by Bryt Ma Tech Uganda${N}"
echo ""

# â”€â”€ Checks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Preflight checks"
[[ $EUID -ne 0 ]]        && fail "Must run as root: sudo bash build.sh"
[[ $(uname -m) != x86_64 ]] && fail "Requires x86_64 host"
command -v debootstrap &>/dev/null || apt-get install -y debootstrap
ok "Running as root"
ok "Architecture: x86_64"

# â”€â”€ Dependencies â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Installing build tools"
apt-get update -qq
apt-get install -y -qq \
    debootstrap squashfs-tools xorriso \
    grub-pc-bin grub-efi-amd64-bin \
    mtools isolinux syslinux-common \
    curl wget ca-certificates rsync \
    whois genisoimage
ok "Build tools installed"

# â”€â”€ Clean build dir â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Preparing build environment"
rm -rf "$WORK"
mkdir -p "$ROOTFS" "$ISO"/{live,boot/grub,EFI/boot}
ok "Build directories created"

# â”€â”€ Bootstrap â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Bootstrapping Debian ${DEBIAN_SUITE} base (3-5 min)"
progress "Downloading base system..."
debootstrap \
    --arch="$TEDDY_ARCH" \
    --variant=minbase \
    "$DEBIAN_SUITE" \
    "$ROOTFS" \
    "$DEBIAN_MIRROR"
ok "Base system ready"

# â”€â”€ Bind mounts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Mounting chroot filesystems"
for fs in dev dev/pts proc sys run; do
    mount --bind "/$fs" "$ROOTFS/$fs" 2>/dev/null || \
    mount --rbind "/$fs" "$ROOTFS/$fs"
done
ok "Chroot filesystems mounted"

cleanup_mounts() {
    for fs in dev/pts dev proc sys run; do
        umount -lf "$ROOTFS/$fs" 2>/dev/null || true
    done
}
trap cleanup_mounts EXIT

# â”€â”€ Write chroot script â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Writing chroot configuration"

cat > "$ROOTFS/teddy-setup.sh" << 'CHROOT_SCRIPT'
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

echo "ðŸ» Teddy OS chroot setup starting..."

# â”€â”€ APT sources â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
cat > /etc/apt/sources.list << 'APT'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free
deb http://deb.debian.org/debian bookworm-updates main contrib non-free
APT

apt-get update -qq

# â”€â”€ Core system â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "Installing core system..."
apt-get install -y --no-install-recommends \
    linux-image-amd64 \
    linux-headers-amd64 \
    live-boot \
    live-boot-initramfs-tools \
    live-config \
    systemd \
    systemd-sysv \
    systemd-resolved \
    dbus \
    udev \
    sudo \
    bash \
    bash-completion \
    coreutils \
    util-linux \
    mount \
    e2fsprogs \
    dosfstools \
    parted \
    gparted \
    ca-certificates \
    apt-transport-https \
    gnupg \
    lsb-release

# â”€â”€ Networking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "Installing networking..."
apt-get install -y --no-install-recommends \
    network-manager \
    network-manager-gnome \
    net-tools \
    wireless-tools \
    wpasupplicant \
    rfkill \
    curl \
    wget \
    openssh-client \
    nmap \
    iputils-ping \
    dnsutils

# â”€â”€ Display system â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "Installing display system..."
apt-get install -y --no-install-recommends \
    xorg \
    xserver-xorg \
    xserver-xorg-video-all \
    xserver-xorg-input-all \
    x11-xserver-utils \
    x11-utils \
    xinit \
    xauth

# â”€â”€ GPU drivers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "Installing GPU drivers..."
apt-get install -y --no-install-recommends \
    xserver-xorg-video-intel \
    xserver-xorg-video-amdgpu \
    xserver-xorg-video-nouveau \
    xserver-xorg-video-vesa \
    xserver-xorg-video-fbdev \
    mesa-utils \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    mesa-vulkan-drivers \
    vainfo \
    intel-media-va-driver-non-free 2>/dev/null || true

# â”€â”€ Desktop environment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "Installing desktop..."
apt-get install -y --no-install-recommends \
    openbox \
    obconf \
    tint2 \
    picom \
    nitrogen \
    dunst \
    rofi \
    feh \
    xdotool \
    wmctrl

# â”€â”€ Display manager â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y --no-install-recommends \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings

# â”€â”€ Fonts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "Installing fonts..."
apt-get install -y --no-install-recommends \
    fonts-noto \
    fonts-noto-color-emoji \
    fonts-noto-cjk \
    fonts-open-sans \
    fonts-ubuntu \
    fonts-firacode \
    fonts-font-awesome \
    fontconfig \
    libfreetype6

# â”€â”€ Themes & icons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y --no-install-recommends \
    papirus-icon-theme \
    arc-theme \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    lxappearance \
    qt5ct

# â”€â”€ File manager & terminal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y --no-install-recommends \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    gvfs \
    gvfs-backends \
    udisks2 \
    xterm \
    xfce4-terminal \
    mousepad

# â”€â”€ Media â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y --no-install-recommends \
    pulseaudio \
    pavucontrol \
    alsa-utils \
    vlc \
    eog \
    evince

# â”€â”€ System tools â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y --no-install-recommends \
    nano \
    vim \
    htop \
    btop \
    neofetch \
    zip \
    unzip \
    tar \
    gzip \
    file \
    lsof \
    strace \
    git \
    rsync \
    screen \
    tmux \
    man-db \
    less \
    tree \
    locate \
    pciutils \
    usbutils \
    lshw \
    dmidecode \
    inxi \
    smartmontools \
    gparted \
    baobab

# â”€â”€ Browser â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "Installing browser..."
apt-get install -y --no-install-recommends chromium || \
apt-get install -y --no-install-recommends chromium-browser || \
apt-get install -y --no-install-recommends firefox-esr
echo "Browser installed"

# â”€â”€ Node.js 20 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 2>/dev/null
apt-get install -y nodejs

# â”€â”€ Electron dependencies â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y --no-install-recommends \
    libgtk-3-0 \
    libnotify4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    libatspi2.0-0 \
    libuuid1 \
    libgbm1 \
    libasound2 \
    libxrandr2 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxfixes3

# â”€â”€ Printer support â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y --no-install-recommends \
    cups \
    system-config-printer \
    printer-driver-all 2>/dev/null || true

# â”€â”€ Bluetooth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y --no-install-recommends \
    bluetooth \
    bluez \
    blueman 2>/dev/null || true

# â”€â”€ Power management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get install -y --no-install-recommends \
    acpi \
    acpid \
    tlp \
    xfce4-power-manager 2>/dev/null || true

# â”€â”€ Locale & timezone â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Africa/Kampala /etc/localtime
echo "Africa/Kampala" > /etc/timezone

# â”€â”€ Users â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "Setting up users..."
useradd -m -s /bin/bash \
    -G sudo,audio,video,netdev,plugdev,bluetooth,cdrom,floppy,lp,scanner \
    teddy 2>/dev/null || true
echo "teddy:teddy" | chpasswd
echo "root:teddyos" | chpasswd
echo "teddy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/teddy
chmod 440 /etc/sudoers.d/teddy

# â”€â”€ Hostname â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo "teddy-os" > /etc/hostname
cat > /etc/hosts << 'HOSTS'
127.0.0.1       localhost
127.0.1.1       teddy-os
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
HOSTS

# â”€â”€ OS identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
mkdir -p /etc/teddy-os
cat > /etc/os-release << 'OSREL'
PRETTY_NAME="Teddy OS 1.0 (Kampala)"
NAME="Teddy OS"
VERSION_ID="1.0"
VERSION="1.0 (Kampala)"
ID=teddyos
ID_LIKE=debian
HOME_URL="https://github.com/YOUR_USERNAME/teddy-os"
SUPPORT_URL="https://github.com/YOUR_USERNAME/teddy-os/issues"
BUG_REPORT_URL="https://github.com/YOUR_USERNAME/teddy-os/issues"
BUILD_ID="bryt-ma-tech-uganda"
ANSI_COLOR="5;35"
LOGO="teddy-os"
OSREL

cat > /etc/teddy-os/release << 'TREL'
TEDDY_OS_VERSION="1.0.0"
TEDDY_OS_CODENAME="Kampala"
TEDDY_OS_BUILT_BY="Bryt Ma Tech Uganda"
TEDDY_OS_ARCH="x86_64"
TEDDY_OS_DATE="2025"
TREL'

# â”€â”€ LightDM â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
cat > /etc/lightdm/lightdm.conf << 'LDM'
[LightDM]
run-directory=/run/lightdm
minimum-vt=7

[Seat:*]
autologin-user=teddy
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
xserver-command=X -nolisten tcp -dpi 96

[XDMCPServer]
enabled=false
LDM

cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'GREETER'
[greeter]
background=#0f0c1a
theme-name=Arc-Dark
icon-theme-name=Papirus-Dark
font-name=Noto Sans 11
clock-format=%H:%M â€” %A, %B %e
indicators=~spacer;~clock;~spacer
position=50%,center 50%,center
GREETER

# â”€â”€ Openbox config for teddy user â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
mkdir -p /home/teddy/.config/openbox
mkdir -p /home/teddy/.config/dunst

cat > /home/teddy/.config/openbox/autostart << 'AUTOSTART'
#!/bin/bash
# Teddy OS autostart

# Compositor (transparency + shadows)
picom --daemon --backend glx --vsync \
    --shadow --shadow-radius 12 --shadow-opacity 0.4 \
    --fading --fade-in-step 0.03 --fade-out-step 0.03 \
    --inactive-opacity 0.97 &

# Wallpaper
nitrogen --restore &

# Taskbar
tint2 &

# Notification daemon
dunst &

# Network manager tray
nm-applet &

# Launch Teddy OS desktop
sleep 1 && /usr/local/bin/teddy-os-launch &
AUTOSTART
chmod +x /home/teddy/.config/openbox/autostart

cat > /home/teddy/.config/openbox/rc.xml << 'OBRC'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance><strength>10</strength><screen_edge_strength>20</screen_edge_strength></resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusDelay>200</focusDelay>
    <raiseOnFocus>no</raiseOnFocus>
  </focus>
  <placement><policy>Smart</policy><center>yes</center><monitor>Primary</monitor></placement>
  <theme>
    <name>Arc-Dark</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
    <font place="ActiveWindow"><name>Noto Sans</name><size>10</size><weight>Bold</weight></font>
    <font place="InactiveWindow"><name>Noto Sans</name><size>10</size><weight>Normal</weight></font>
    <font place="MenuHeader"><name>Noto Sans</name><size>10</size><weight>Bold</weight></font>
    <font place="MenuItem"><name>Noto Sans</name><size>10</size><weight>Normal</weight></font>
  </theme>
  <desktops>
    <number>1</number>
    <firstdesk>1</firstdesk>
    <names><name>Teddy OS</name></names>
    <popupTime>0</popupTime>
  </desktops>
  <resize><drawContents>yes</drawContents><popupShow>Never</popupShow></resize>
  <margins><top>0</top><bottom>38</bottom><left>0</left><right>0</right></margins>
  <keyboard>
    <rebindOnMappingNotify>yes</rebindOnMappingNotify>
    <chainQuitKey>C-g</chainQuitKey>
    <keybind key="super"><action name="Execute"><command>/usr/local/bin/teddy-os-launch</command></action></keybind>
    <keybind key="super-e"><action name="Execute"><command>xfce4-terminal</command></action></keybind>
    <keybind key="super-f"><action name="Execute"><command>thunar</command></action></keybind>
    <keybind key="super-b"><action name="Execute"><command>chromium --new-window</command></action></keybind>
    <keybind key="Print"><action name="Execute"><command>scrot ~/Pictures/screenshot-%Y%m%d-%H%M%S.png</command></action></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="A-Tab"><action name="NextWindow"><dialog>no</dialog><linear>no</linear><bar>no</bar><raise>no</raise><allDesktops>no</allDesktops></action></keybind>
    <keybind key="super-Left"><action name="MaximizeHalf"><direction>Left</direction></action></keybind>
    <keybind key="super-Right"><action name="MaximizeHalf"><direction>Right</direction></action></keybind>
    <keybind key="super-Up"><action name="MaximizeFull"/></keybind>
    <keybind key="super-Down"><action name="Unmaximize"/></keybind>
  </keyboard>
  <mouse>
    <dragThreshold>1</dragThreshold>
    <doubleClickTime>200</doubleClickTime>
    <screenEdgeWarpTime>0</screenEdgeWarpTime>
    <context name="Desktop">
      <mousebind button="Right" action="Press">
        <action name="Execute"><command>/usr/local/bin/teddy-os-launch</command></action>
      </mousebind>
    </context>
    <context name="Client">
      <mousebind button="Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="Left" action="DoubleClick"><action name="MaximizeFull"/></mousebind>
      <mousebind button="Right" action="Press">
        <action name="Focus"/><action name="Raise"/>
        <action name="ShowMenu"><menu>client-menu</menu></action>
      </mousebind>
    </context>
    <context name="Handle">
      <mousebind button="Left" action="Drag"><action name="Resize"/></mousebind>
    </context>
    <context name="Border">
      <mousebind button="Left" action="Drag"><action name="Resize"/></mousebind>
    </context>
  </mouse>
  <applications>
    <application name="TeddyOS" class="TeddyOS">
      <decor>no</decor>
      <maximized>true</maximized>
      <layer>below</layer>
    </application>
    <application name="chromium" class="Chromium">
      <maximized>false</maximized>
    </application>
  </applications>
</openbox_config>
OBRC

# â”€â”€ tint2 taskbar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
mkdir -p /home/teddy/.config/tint2
cat > /home/teddy/.config/tint2/tint2rc << 'TINT2'
#---- Background definitions
rounded = 0
border_width = 0
background_color = #0a0614 100
border_color = #ffffff 0

rounded = 0
border_width = 1
background_color = #1e1a30 100
border_color = #a855f7 40

#---- Panel
panel_items = LTSC
panel_size = 100% 38
panel_margin = 0 0
panel_padding = 6 0 6
panel_dock = 0
panel_position = bottom left horizontal
font_shadow = 0
panel_background_id = 1
wm_menu = 1
panel_layer = top
panel_monitor = all
primary_monitor_first = 0

#---- Taskbar
taskbar_mode = single_desktop
taskbar_padding = 2 3 2
taskbar_background_id = 0
taskbar_active_background_id = 0
taskbar_name = 0
taskbar_hide_inactive_tasks = 0
taskbar_hide_different_monitor = 0
taskbar_always_show_all_desktop_tasks = 0
taskbar_sort_order = none
task_align = left

#---- Tasks
task_text = 1
task_icon = 1
task_centered = 1
urgent_nb_of_blink = 8
task_maximum_size = 160 35
task_padding = 6 3 6
task_font = Noto Sans 10
task_font_color = #a89ec8 100
task_active_font_color = #f0eeff 100
task_background_id = 0
task_active_background_id = 2
task_urgent_background_id = 2
task_iconified_background_id = 0

#---- System tray
systray_padding = 4 4 4
systray_background_id = 0
systray_sort = ascending
systray_icon_size = 20
systray_icon_asb = 100 0 0
systray_monitor = 1
systray_name_filter =

#---- Clock
time1_format = %H:%M
time1_font = Noto Sans Bold 11
time1_font_color = #f0eeff 100
time2_format = %a %d %b
time2_font = Noto Sans 9
time2_font_color = #6b6085 100
clock_font_color = #f0eeff 100
clock_padding = 4 0
clock_background_id = 0
clock_tooltip = %A %e %B %Y
TINT2

# â”€â”€ dunst notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
cat > /home/teddy/.config/dunst/dunstrc << 'DUNST'
[global]
monitor = 0
follow = mouse
geometry = "360x5-16+52"
indicate_hidden = yes
shrink = no
transparency = 8
notification_height = 0
separator_height = 2
padding = 12
horizontal_padding = 14
frame_width = 1
frame_color = "#a855f7"
separator_color = frame
sort = yes
idle_threshold = 120
font = Noto Sans 11
line_height = 0
markup = full
format = "<b>%s</b>\n%b"
alignment = left
show_age_threshold = 60
word_wrap = yes
ellipsize = middle
ignore_newline = no
stack_duplicates = true
hide_duplicate_count = false
show_indicators = yes
icon_position = left
max_icon_size = 32
sticky_history = yes
history_length = 20
browser = chromium
always_run_script = true
title = Dunst
class = Dunst
startup_notification = false
verbosity = mesg
corner_radius = 8
ignore_dbusclose = false
mouse_left_click = close_current
mouse_middle_click = do_action, close_current
mouse_right_click = close_all

[urgency_low]
background = "#16122a"
foreground = "#a89ec8"
frame_color = "#3d3060"
timeout = 4

[urgency_normal]
background = "#16122a"
foreground = "#f0eeff"
frame_color = "#a855f7"
timeout = 6

[urgency_critical]
background = "#2d0a1a"
foreground = "#f0eeff"
frame_color = "#f87171"
timeout = 0
DUNST

# â”€â”€ GTK theme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
mkdir -p /home/teddy/.config/gtk-3.0
cat > /home/teddy/.config/gtk-3.0/settings.ini << 'GTK3'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
GTK3

cat > /home/teddy/.gtkrc-2.0 << 'GTK2'
gtk-theme-name="Arc-Dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Noto Sans 11"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintslight"
gtk-xft-rgba="rgb"
GTK2

# â”€â”€ Launcher scripts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
cat > /usr/local/bin/teddy-os-launch << 'LAUNCH'
#!/bin/bash
# Teddy OS app launcher
# Tries Electron first, falls back to Chromium app mode

ELECTRON_APP="/opt/teddy-os/TeddyOS"
WEB_BUILD="/opt/teddy-os/index.html"

if [ -x "$ELECTRON_APP" ]; then
    exec "$ELECTRON_APP" \
        --no-sandbox \
        --disable-gpu-sandbox \
        --class=TeddyOS \
        --name=TeddyOS
elif [ -f "$WEB_BUILD" ]; then
    exec chromium \
        --app="file://$WEB_BUILD" \
        --class=TeddyOS \
        --window-size=1920,1080 \
        --start-maximized \
        --no-sandbox \
        --disable-infobars \
        --disable-features=TranslateUI \
        --disable-session-crashed-bubble \
        --disable-dev-shm-usage
else
    # Show setup screen
    xterm -title "Teddy OS Setup" -e bash /usr/local/bin/teddy-os-setup
fi
LAUNCH
chmod +x /usr/local/bin/teddy-os-launch

cat > /usr/local/bin/teddy-os-setup << 'SETUP'
#!/bin/bash
echo ""
echo "ðŸ» Teddy OS"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "Built by Bryt Ma Tech Uganda"
echo ""
echo "Teddy OS app not found at /opt/teddy-os/"
echo ""
echo "To install:"
echo "  1. Copy your built Teddy OS app:"
echo "     cp -r teddy-os/build/* /opt/teddy-os/"
echo "  OR"
echo "     cd /opt/teddy-os && npm install && npm run build"
echo ""
echo "  2. Then run: teddy-os-launch"
echo ""
read -rp "Press Enter to open a terminal..."
exec xfce4-terminal
SETUP
chmod +x /usr/local/bin/teddy-os-setup

# â”€â”€ Wallpaper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
mkdir -p /usr/share/backgrounds/teddy-os
cat > /usr/share/backgrounds/teddy-os/default.svg << 'WALL'
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
  <defs>
    <radialGradient id="g1" cx="25%" cy="35%" r="60%">
      <stop offset="0%" stop-color="#1a0a2e"/>
      <stop offset="100%" stop-color="#0a0614"/>
    </radialGradient>
    <radialGradient id="g2" cx="75%" cy="65%" r="50%">
      <stop offset="0%" stop-color="#0f0c1a"/>
      <stop offset="100%" stop-color="#06030e"/>
    </radialGradient>
    <filter id="blur"><feGaussianBlur stdDeviation="80"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#g1)"/>
  <rect width="1920" height="1080" fill="url(#g2)" opacity="0.6"/>
  <circle cx="320" cy="280" r="420" fill="#a855f7" opacity="0.05" filter="url(#blur)"/>
  <circle cx="1600" cy="800" r="380" fill="#60a5fa" opacity="0.04" filter="url(#blur)"/>
  <circle cx="960" cy="1000" r="300" fill="#a855f7" opacity="0.03" filter="url(#blur)"/>
  <text x="960" y="460" text-anchor="middle"
    font-family="Noto Sans, sans-serif" font-size="72"
    font-weight="200" fill="#c084fc" opacity="0.55">ðŸ»</text>
  <text x="960" y="548" text-anchor="middle"
    font-family="Noto Sans, sans-serif" font-size="32"
    font-weight="300" fill="#9333ea" opacity="0.5"
    letter-spacing="6">TEDDY OS</text>
  <text x="960" y="588" text-anchor="middle"
    font-family="Noto Sans, sans-serif" font-size="13"
    font-weight="300" fill="#6b6085" opacity="0.7"
    letter-spacing="3">BUILT BY BRYT MA TECH UGANDA</text>
</svg>
WALL

# Set as nitrogen config
mkdir -p /home/teddy/.config
cat > /home/teddy/.config/nitrogen.cfg << 'NITRO'
[xin_-1]
file=/usr/share/backgrounds/teddy-os/default.svg
mode=5
bgcolor=#0f0c1a
NITRO

# â”€â”€ Neofetch branding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
cat > /etc/profile.d/teddy-motd.sh << 'MOTD'
#!/bin/bash
if [ -f /usr/bin/neofetch ]; then
    neofetch --ascii_distro ubuntu \
        --colors 5 5 5 5 5 5 \
        --print_info title \
        --print_info os \
        --print_info kernel \
        --print_info memory \
        --print_info cpu \
        --print_info disk 2>/dev/null || true
fi
echo ""
echo "  ðŸ» Welcome to Teddy OS â€” Built by Bryt Ma Tech Uganda"
echo ""
MOTD
chmod +x /etc/profile.d/teddy-motd.sh

# â”€â”€ Services â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
systemctl enable NetworkManager
systemctl enable lightdm
systemctl enable bluetooth 2>/dev/null || true
systemctl enable cups 2>/dev/null || true

# â”€â”€ Fix permissions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
chown -R teddy:teddy /home/teddy
mkdir -p /opt/teddy-os
chown -R teddy:teddy /opt/teddy-os

# â”€â”€ Cleanup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
apt-get autoremove -y --purge
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -f /etc/ssh/ssh_host_*
history -c

echo ""
echo "âœ… Teddy OS chroot setup complete"
CHROOT_SCRIPT

chmod +x "$ROOTFS/teddy-setup.sh"

# â”€â”€ Run chroot setup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Configuring Teddy OS inside chroot (10-20 min)"
chroot "$ROOTFS" /teddy-setup.sh
rm -f "$ROOTFS/teddy-setup.sh"
ok "Chroot configuration complete"

# â”€â”€ Copy Teddy OS desktop app â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Installing Teddy OS desktop application"
mkdir -p "$ROOTFS/opt/teddy-os"

if [ -d "./desktop/build" ]; then
    cp -r ./desktop/build/* "$ROOTFS/opt/teddy-os/"
    ok "Teddy OS web build installed from ./desktop/build"
elif [ -d "./teddy-os/build" ]; then
    cp -r ./teddy-os/build/* "$ROOTFS/opt/teddy-os/"
    ok "Teddy OS web build installed"
else
    warn "No desktop build found â€” will prompt user on first boot"
    warn "Before building ISO: cd desktop && npm install && npm run build"
fi

# â”€â”€ Squash filesystem â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Compressing filesystem (5-15 min)"
progress "Creating squashfs with xz compression..."
mksquashfs "$ROOTFS" "$ISO/live/filesystem.squashfs" \
    -comp xz \
    -Xbcj x86 \
    -b 1048576 \
    -noappend \
    -no-progress \
    -wildcards \
    -e boot 2>/dev/null
ok "Filesystem compressed: $(du -sh "$ISO/live/filesystem.squashfs" | cut -f1)"

# â”€â”€ Kernel + initrd â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Copying kernel and initramfs"
KERNEL=$(ls "$ROOTFS/boot/vmlinuz-"* | head -1)
INITRD=$(ls "$ROOTFS/boot/initrd.img-"* | head -1)
cp "$KERNEL" "$ISO/live/vmlinuz"
cp "$INITRD" "$ISO/live/initrd.img"
ok "Kernel: $(basename "$KERNEL")"
ok "Initrd: $(basename "$INITRD")"

# â”€â”€ GRUB config â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Writing bootloader configuration"

cat > "$ISO/boot/grub/grub.cfg" << GRUBCFG
# â”€â”€â”€ Teddy OS GRUB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

menuentry "ðŸ»  Boot Teddy OS ${TEDDY_VERSION}" --class teddy-os {
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

menuentry "ðŸ”§  Boot Teddy OS â€” Safe mode" --class teddy-os {
    linux  /live/vmlinuz \\
        boot=live \\
        nomodeset \\
        hostname=teddy-os \\
        username=teddy \\
        locales=en_US.UTF-8 \\
        components
    initrd /live/initrd.img
}

menuentry "ðŸ’¿  Install Teddy OS to hard drive" --class install {
    linux  /live/vmlinuz \\
        boot=live \\
        components \\
        quiet \\
        hostname=teddy-os \\
        username=teddy
    initrd /live/initrd.img
}

menuentry "ðŸ–¥  Boot from hard drive" --class harddisk {
    set root=(hd0)
    chainloader +1
}

menuentry "ðŸ§ª  Memory test (memtest86+)" --class memtest {
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

# â”€â”€ Build ISO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
step "Building ISO image"
progress "Running xorriso..."

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "TEDDYOS_10" \
    -appid "Teddy OS ${TEDDY_VERSION} â€” Bryt Ma Tech Uganda" \
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

# â”€â”€ Done â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo ""
echo -e "${B}${G}"
echo "  â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo "  ðŸ»  TEDDY OS ISO READY"
echo "  â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo -e "${N}"
echo "  File : $OUTPUT"
echo "  Size : $(du -sh "$OUTPUT" | cut -f1)"
echo "  Built: $(date)"
echo ""
echo "  â”€â”€ Flash to USB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€"
echo "  Linux/Mac:"
echo "    sudo dd if=$OUTPUT of=/dev/sdX bs=4M status=progress"
echo ""
echo "  Windows: Use balenaEtcher â€” https://etcher.balena.io"
echo ""
echo "  â”€â”€ Boot your laptop â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€"
echo "  Insert USB â†’ restart â†’ press F12 (or F8/F9/Esc)"
echo "  Select USB drive from boot menu"
echo ""
echo "  â”€â”€ Install permanently â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€"
echo "  Once booted: sudo bash /opt/teddy-os/install.sh"
echo ""
echo -e "  ${Y}Built by Bryt Ma Tech Uganda${N}"
echo ""

# NOTE: All branding is already embedded in the build script above.
# Key branding locations:
# - /etc/os-release          â†’ "Teddy OS" identity
# - /etc/teddy-os/release    â†’ Bryt Ma Tech Uganda
# - GRUB menu                â†’ ðŸ» Teddy OS branding
# - Wallpaper SVG            â†’ "Built by Bryt Ma Tech Uganda"
# - Neofetch MOTD            â†’ Shows on every terminal open
# - ISO publisher field      â†’ "Bryt Ma Tech Uganda"
# - tint2 taskbar            â†’ Shows "Teddy OS" bottom bar
# - LightDM greeter          â†’ Custom dark login screen
