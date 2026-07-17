<div align="center">

# 🐻 Teddy OS

### A lightweight, AI-powered Linux operating system

**Built by Bryt Ma Tech Uganda 🇺🇬**

[![Build ISO](https://github.com/YOUR_USERNAME/teddy-os/actions/workflows/build-iso.yml/badge.svg)](https://github.com/YOUR_USERNAME/teddy-os/actions/workflows/build-iso.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![Made in Uganda](https://img.shields.io/badge/Made%20in-Uganda%20🇺🇬-yellow.svg)]()
[![Version](https://img.shields.io/badge/Version-1.0.0%20Kampala-blueviolet.svg)]()

---

[**⬇️ Download Latest ISO**](https://github.com/YOUR_USERNAME/teddy-os/releases/latest) &nbsp;·&nbsp;
[**📖 Install Guide**](iso-builder/README.md) &nbsp;·&nbsp;
[**🐛 Report Issue**](https://github.com/YOUR_USERNAME/teddy-os/issues)

</div>

---

## What is Teddy OS?

Teddy OS is a **free, lightweight Linux operating system** built from the ground up in Uganda. It boots directly on your laptop — no Windows or macOS required underneath. It comes with a full suite of productivity apps including an **AI-powered document editor**, terminal, file manager, calendar, and calculator.

> *The first operating system built in East Africa — for the world.*

---

## Why Teddy OS?

| | Windows 11 | Ubuntu | **Teddy OS** |
|---|---|---|---|
| **Price** | ~$139 | Free | **Free** |
| **RAM usage** | 4GB+ | 1GB+ | **512MB+** |
| **Install size** | 27GB | 8GB | **~2GB** |
| **Bloatware** | Yes | Some | **Zero** |
| **AI assistant** | $30/month extra | None | **Built in, free** |
| **Boot time** | 30-60s | 20-40s | **<10 seconds** |
| **Old hardware** | No (2018+) | Partial | **Yes (2008+)** |
| **Built in Uganda** | ❌ | ❌ | **✅** |

---

## Built-in Apps

| App | Description |
|-----|-------------|
| 📝 **Document Editor** | Rich text editor with formatting, PDF export, and AI writing assistance. Replaces Microsoft Word. |
| ✨ **AI Assistant** | Claude-powered AI built directly into the OS. Write, improve, summarize, brainstorm. |
| 💻 **Terminal** | Full Linux terminal with 15+ commands, command history, arrow key navigation. |
| 📁 **File Manager** | Grid and list view, search, open and manage your documents. |
| 🔢 **Calculator** | Full arithmetic with calculation history and keyboard support. |
| 📅 **Calendar** | Monthly view with event creation, time-based reminders, and persistence. |
| ⚙️ **Settings** | Font, autosave, line height, storage management. |
| 👤 **User Accounts** | Login screen, multiple users, lock screen, avatars. |
| 🔔 **Notifications** | System-wide notification toasts and notification tray. |

---

## Screenshots

> *Coming soon — boot Teddy OS on your laptop and send us a photo!*

---

## Quick Start

### Download and install (easiest)

1. Go to [**Releases**](https://github.com/YOUR_USERNAME/teddy-os/releases/latest)
2. Download `teddyos-1.0.0-x86_64.iso`
3. Flash to USB with [balenaEtcher](https://etcher.balena.io)
4. Boot your laptop from the USB
5. Teddy OS loads automatically

### Install permanently to your hard drive

Once booted from USB, open the terminal and run:
```bash
sudo bash /opt/teddy-os/install.sh
```

Full guide: [iso-builder/README.md](iso-builder/README.md)

---

## Build from source

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/teddy-os.git
cd teddy-os

# 2. Build the desktop app
cd desktop && npm install && npm run build && cd ..

# 3. Build the ISO (on Ubuntu 22.04+)
cd iso-builder && sudo bash build.sh

# OR — let GitHub build it for you (free):
# Push to main branch → GitHub Actions builds the ISO automatically
```

### Build with GitHub Actions (no Ubuntu needed)

1. Fork this repo
2. Go to **Actions** tab → **Build Teddy OS ISO** → **Run workflow**
3. Wait ~25 minutes
4. Download the ISO from the workflow artifacts

---

## Hardware requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | x86_64 dual-core (2008+) | 2GHz+ quad-core |
| RAM | 1GB | 4GB+ |
| Storage | 8GB | 20GB+ SSD |
| USB drive | 2GB | 4GB+ |

---

## Default login

| Username | Password |
|----------|----------|
| `teddy` | `teddy` |

Change immediately after install: `passwd`

---

## Project structure

```
teddy-os/
├── .github/workflows/
│   └── build-iso.yml     ← GitHub Actions — auto-builds ISO
├── desktop/
│   ├── src/
│   │   ├── App.jsx        ← Main OS shell
│   │   ├── apps/          ← Editor, AI, Calc, Calendar, Terminal, Files, Settings
│   │   ├── components/    ← Window, Auth, Notifications
│   │   ├── hooks/         ← useWindowManager
│   │   └── utils/         ← IndexedDB helpers
│   ├── electron/          ← Desktop app wrapper
│   ├── public/            ← HTML + PWA manifest
│   └── package.json
├── iso-builder/
│   ├── build.sh           ← Builds the bootable ISO
│   ├── install.sh         ← Installs to hard drive
│   └── README.md
└── README.md              ← This file
```

---

## Roadmap

- [x] Bootable ISO (BIOS + UEFI)
- [x] Hard drive installer
- [x] AI-powered document editor
- [x] Terminal, Calculator, Calendar, File Manager
- [x] User login + lock screen
- [x] Notifications
- [x] GitHub Actions auto-build
- [ ] `.docx` file support (full Word replacement)
- [ ] Built-in web browser
- [ ] App store
- [ ] Luganda + Swahili language support
- [ ] ARM / Raspberry Pi build
- [ ] OEM installer for schools

---

## Contributing

Pull requests welcome. Open an issue first to discuss what you'd like to change.

---

## License

MIT © 2025 [Bryt Ma Tech Uganda](https://github.com/YOUR_USERNAME)

---

<div align="center">
  <strong>🐻 Teddy OS — Built with ❤️ in Uganda</strong><br/>
  <sub>Bryt Ma Tech Uganda · Kampala, Uganda 🇺🇬</sub>
</div>
