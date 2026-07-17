# 🐻 Teddy OS
### A lightweight Linux operating system — Built by Bryt Ma Tech Uganda

---

## What is Teddy OS?

Teddy OS is a full Linux-based operating system that boots directly on your laptop.
No Windows required underneath. Built on Debian, runs the Teddy OS desktop as the
primary interface — with a built-in AI assistant, document editor, terminal, file
manager, calculator, and calendar.

**Why Teddy OS over Windows?**

| | Windows 11 | Teddy OS |
|---|---|---|
| Cost | ~$139 | Free |
| RAM usage | 4GB+ | 512MB+ |
| Install size | 27GB+ | ~2GB |
| Bloatware | Yes | Zero |
| AI assistant | Costs extra | Built in |
| Boot time | 30-60s | <10s |
| Works on old hardware | No | Yes |
| Made in Uganda | No | Yes |

---

## Requirements to build the ISO

| Item | Minimum |
|------|---------|
| Host OS | Ubuntu 22.04 or 24.04 (x86_64) |
| RAM | 4GB |
| Free disk | 20GB |
| Internet | Required during build |
| Time | 15-30 minutes |

---

## Step 1 — Build the Teddy OS desktop app

```bash
# Inside the desktop/ folder
cd desktop
npm install
npm run build
cd ..
```

This creates `desktop/build/` — the web app that runs inside the OS.

---

## Step 2 — Build the ISO

```bash
cd iso-builder
sudo bash build.sh
```

Output: `teddyos-1.0.0-x86_64.iso` (~800MB-1.2GB)

---

## Step 3 — Flash to USB drive

### Linux / Mac
```bash
# Find your USB (look for your device, e.g. /dev/sdb)
lsblk

# Flash it (replace sdX with your USB drive — NOT your hard drive!)
sudo dd if=teddyos-1.0.0-x86_64.iso of=/dev/sdX bs=4M status=progress
sync
```

### Windows
1. Download **balenaEtcher**: https://etcher.balena.io
2. Select `teddyos-1.0.0-x86_64.iso`
3. Select your USB drive
4. Click Flash

---

## Step 4 — Boot from USB

1. Insert USB into your laptop
2. Restart the laptop
3. Press the boot menu key while it starts:

| Brand | Key |
|-------|-----|
| Dell | F12 |
| HP | F9 or Esc |
| Lenovo | F12 or F11 |
| ASUS | F8 or Esc |
| Acer | F12 |
| Toshiba | F12 |

4. Select your USB drive from the boot menu
5. Choose **"Boot Teddy OS"** from the GRUB menu
6. Teddy OS boots automatically and logs in as user `teddy`

---

## Step 5 — Install permanently to hard drive

Once booted from USB, open a terminal and run:

```bash
sudo bash /opt/teddy-os/install.sh
```

Follow the prompts. When done:
1. Remove the USB
2. `sudo reboot`
3. Teddy OS loads from your hard drive every time you start your laptop

---

## Default login

| Username | Password |
|----------|----------|
| teddy | teddy |

**Change your password immediately after install:**
```bash
passwd
```

---

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| Super (Windows key) | Open Teddy OS / launcher |
| Super + E | Open terminal |
| Super + F | Open file manager |
| Super + B | Open browser |
| Super + ← / → | Snap window left/right |
| Super + ↑ | Maximize window |
| Alt + F4 | Close window |
| Alt + Tab | Switch windows |
| Print Screen | Screenshot |

---

## Hardware requirements (to run Teddy OS)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | x86_64 dual-core | 2GHz+ quad-core |
| RAM | 1GB | 4GB+ |
| Storage | 8GB | 20GB+ |
| Display | 1024×768 | 1920×1080 |
| USB (for install) | 2GB | 4GB+ |

Works on laptops as old as 2009 (Core 2 Duo era).

---

## Troubleshooting

**Black screen after boot:**
- Select "Safe mode" from the GRUB menu (no splash, nomodeset)
- This disables GPU acceleration and works on almost all hardware

**No WiFi:**
```bash
sudo nmtui
# Select "Activate a connection" and connect to your network
```

**Teddy OS app doesn't load:**
```bash
# Manually launch
/usr/local/bin/teddy-os-launch

# Or open in browser
chromium --app=file:///opt/teddy-os/index.html
```

**USB won't boot:**
- Enter BIOS (usually F2 or Del at startup)
- Disable Secure Boot
- Set boot order: USB first
- Try Legacy/BIOS mode if UEFI doesn't work

**Sound not working:**
```bash
sudo alsa-restore
pulseaudio --start
```

---

## Project structure

```
teddyos/
├── iso-builder/
│   ├── build.sh        ← Run this to build the ISO
│   ├── install.sh      ← Run inside live session to install to disk
│   └── README.md       ← This file
└── desktop/
    ├── src/            ← React source code
    ├── electron/       ← Electron desktop wrapper
    ├── public/         ← HTML + PWA manifest
    └── package.json    ← Build config
```

---

## Push to GitHub

```bash
git init
git add .
git commit -m "🐻 Teddy OS v1.0 — Kampala"
git remote add origin https://github.com/YOUR_USERNAME/teddy-os.git
git push -u origin main
```

Then create a GitHub Release and attach the `.iso` file so people can download it.

---

## Roadmap

- [x] Bootable ISO (BIOS + UEFI)
- [x] Hard drive installer
- [x] Openbox desktop with tint2 taskbar
- [x] Auto-login live session
- [x] AI-powered document editor
- [x] Terminal, Calculator, Calendar, File Manager
- [x] User login + lock screen
- [x] Notifications system
- [ ] .docx file support (Word replacement)
- [ ] Built-in browser app
- [ ] App store / package manager
- [ ] Multi-language support (Luganda, Swahili)
- [ ] OEM installer for schools and businesses
- [ ] ARM / Raspberry Pi build

---

**🐻 Teddy OS — Built with ❤️ in Uganda by Bryt Ma Tech Uganda**
