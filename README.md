<div align="center">

# 🐻 Teddy OS

### A calm, protective, accessibility-first Linux desktop

**Built by Bryt Ma Tech UG**

[![Build Teddy OS ISO](https://github.com/muhumuza684/teddy-os/actions/workflows/build-iso.yml/badge.svg)](https://github.com/muhumuza684/teddy-os/actions/workflows/build-iso.yml)
[![Teddy OS Quality Checks](https://github.com/muhumuza684/teddy-os/actions/workflows/quality.yml/badge.svg)](https://github.com/muhumuza684/teddy-os/actions/workflows/quality.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.2.0--dev-blueviolet.svg)](https://github.com/muhumuza684/teddy-os/releases)
[![Made in Uganda](https://img.shields.io/badge/Made%20in-Uganda-yellow.svg)](https://github.com/muhumuza684)

**Teddy OS is designed to make computers easier to understand, safer to use, and lighter on everyday hardware.**

[Download latest build](https://github.com/muhumuza684/teddy-os/actions) · [Build from source](#build-from-source) · [Report an issue](https://github.com/muhumuza684/teddy-os/issues) · [Read the Version 2.1 plan](docs/TEDDY-V2.1-IMPLEMENTATION.md)

</div>

---

## The idea

Most operating systems expose users to too many menus, technical terms, hidden consequences, and irreversible actions. Teddy OS takes a different direction: it gives people a clear way forward, explains important changes, and protects their work.

> **Teddy OS should be light enough for an older laptop and clear enough for someone using a computer for the first time.**

Teddy is being built in Uganda by **Bryt Ma Tech UG** as a focused desktop system for people who want a calm, friendly, practical computer rather than a crowded collection of services and settings.

## What is working today

Teddy OS Version 2.1 has a successful automated ISO pipeline. The desktop application builds, the Debian-based root filesystem is created, the root filesystem is packaged safely, and the final BIOS/UEFI ISO is produced by GitHub Actions. The separate quality workflow checks the desktop build, release files, shell syntax, and unwanted external AI-provider references.

The current public build is an active foundation rather than a claim that every future feature is complete. Booting and installation should still be validated in QEMU or VirtualBox before using an image on physical hardware.

## Three ways to use Teddy

| Mode | Designed for | Experience |
|---|---|---|
| **Simple Mode** | People who want a calm, focused desktop | Common applications, reduced choices, and a friendly starting surface |
| **Advanced Mode** | Experienced users and developers | Full tools including Terminal, diagnostics, settings, and the complete application set |
| **Care Mode** | People who need more guidance or accessibility support | Reduced distractions, clearer assistance, larger guided surfaces, and a foundation for speech and high-contrast features |

Modes can be changed from the mode center, and the selected mode is remembered for the local user.

## Built around protection

Teddy OS is not designed to give an assistant unrestricted control of the computer. Its safety direction is deterministic first: the system should preview changes, request confirmation, keep recovery options, and explain what happened.

Version 2.1 includes a **Teddy Guardian** foundation in Settings. Users can export their saved documents to a JSON backup and restore them after validation and confirmation. The project roadmap expands this into version history, checksums, restore points, safe updates, and rollback.

New local users are stored using salted PBKDF2 password hashing in the desktop layer, with migration support for older local records. The native-shell roadmap will move security-sensitive operations into a properly controlled host layer.

## Offline by design

Teddy OS does not require an external AI service to boot or perform its core tasks. Teddy Help and editor text transformations run locally. Search, settings guidance, diagnostics, backups, and recovery are intended to remain useful without a network connection or GPU.

An optional local intelligence module may be added later for selected tasks such as explaining an error or summarizing selected text. It will not be permitted to delete files, partition disks, install packages, change passwords, or modify security settings without deterministic checks and explicit confirmation.

## Included applications

| Application | Purpose |
|---|---|
| **Document Editor** | Write, format, autosave, print, and export documents |
| **Teddy Help** | Offline guidance and local explanations without an external provider |
| **File Manager** | Browse and manage the local document workspace |
| **Terminal** | Access practical Linux commands in Advanced Mode |
| **Calculator** | Perform calculations with keyboard support and history |
| **Calendar** | View months, add events, and manage reminders |
| **Browser** | Browse the web inside Teddy (address bar, back/forward, reload) |
| **Clock** | World clock, alarms with notifications, timer, and stopwatch |
| **Software Center** | Install common apps (Wine, Docker, GIMP, VLC, Codium, fingerprint support); not shown in Care Mode |
| **Settings** | Configure the desktop, accessibility preferences, fingerprint login, keyboard and mouse, storage, backup, and restore |
| **User accounts** | First-run setup, multiple users, lock screen, avatars, and logout |
| **Notifications** | Receive system messages through the notification tray |

## Why the build has three ISO stages

The ISO pipeline is intentionally separated into three jobs:

```text
Desktop source
    ↓
Build Teddy OS Desktop App
    ↓  teddy-os-desktop-build artifact
Build Teddy OS Rootfs
    ↓  teddy-os-rootfs artifact
Build Teddy OS ISO
    ↓
Downloadable BIOS/UEFI ISO
```

The desktop job compiles the user interface. The rootfs job creates the Linux filesystem and installs the desktop into it. The ISO job compresses the filesystem and creates the bootable image. A separate **Teddy OS Quality Checks** workflow verifies source quality without waiting for a complete ISO build.

This structure made it possible to fix the earlier six-hour packaging timeout and identify failures by responsibility instead of hiding every operation inside one long job.

## Lightweight direction

Teddy OS currently uses a Debian base with Openbox, LightDM, and a desktop application. The project is lightweight-oriented, but the current Electron compatibility shell means the runtime should not yet be described as ultra-lightweight. The main architectural objective for the next release is to replace Electron with a carefully scoped native shell while preserving the tested interface.

Lightweight performance will be measured rather than guessed. The repository includes scripts for recording memory, storage, uptime, processes, service timing, ISO size, and checksums. Each release should publish measured results for a defined test machine.

## Download and test

The latest ISO is produced as a GitHub Actions artifact. Open the [Actions page](https://github.com/muhumuza684/teddy-os/actions), select a successful **Build Teddy OS ISO** run, and download the `teddy-os-iso` artifact.

Test in a virtual machine first. Recommended starting resources are 4 GB RAM, 2 virtual CPUs, and a 32 GB virtual disk. Test booting, login, all three modes, networking, document backup and restore, shutdown, restart, and installation to the virtual disk. Do not install on a physical disk until the virtual-disk test is successful and important data is backed up.

## Install next to Windows

On UEFI computers the installer offers **Install alongside Windows**. Before it changes anything it checks that the disk is GPT, that Windows is found, that BitLocker is off, that Windows is fully shut down (no hibernation or Fast Startup), that no disk check is pending, and that enough space can be freed. If any check fails it explains why and leaves the disk untouched. If it proceeds, it backs up the partition table, shrinks Windows, creates the Teddy OS partition, reuses the existing EFI partition without formatting it, and restores the original partition table automatically if any step fails. GRUB then lists Windows beside Teddy OS.

This path is tested on scratch disk images, **not yet on real hardware**. Always try it in a UEFI virtual machine first (see `docs/TEDDY-V2.2-SYSTEM-FEATURES.md`) and back up important data.

New to the project or starting from a clean machine? Read `docs/DEVELOPMENT.md` (setup, rules, tests, workflow, VM testing, troubleshooting).

## Build from source

### Desktop application

```bash
git clone https://github.com/muhumuza684/teddy-os.git
cd teddy-os/desktop
npm install
npm run build
```

### ISO on Ubuntu

```bash
cd ..
cd iso-builder
sudo bash build.sh
```

`build.sh` runs the same two stages as GitHub Actions (`build-rootfs.sh`, then `build-image.sh`). The product version is defined once, in `desktop/package.json`, and flows into the desktop UI, the ISO file name, and the installed `os-release`.

The ISO builder requires a Linux environment with root privileges and the tools documented in [`iso-builder/README.md`](iso-builder/README.md).

### GitHub Actions

Push to `main`, or run the workflows manually from the repository’s **Actions** tab. The ISO workflow builds the application, creates the root filesystem, and creates the ISO. The quality workflow runs the faster source and desktop checks.

## Project structure

```text
teddy-os/
├── .github/workflows/
│   ├── build-iso.yml              # Desktop → rootfs → ISO pipeline
│   └── quality.yml                # Build, source-quality, consistency, and system tests
├── desktop/
│   ├── src/
│   │   ├── App.jsx                # Main desktop shell and mode routing
│   │   ├── apps/                  # Editor, Help, Files, Browser, Clock, Store, Settings, and tools
│   │   ├── components/            # Windows, authentication, modes, notifications
│   │   └── utils/                 # Local persistence helpers and the product version
│   ├── electron/                  # Current compatibility host (main, preload, system-ipc)
│   └── package.json               # The single source of truth for the version
├── iso-builder/
│   ├── build.sh                   # One-command local build (runs the two stages below)
│   ├── build-rootfs.sh            # Debian rootfs construction
│   ├── build-image.sh             # Bootable ISO construction
│   ├── install.sh                 # Installer (erase disk, or install alongside Windows)
│   ├── lib/                       # alongside.sh safety library and its installer menu
│   └── README.md
├── native-shell/
│   └── README.md                  # Native-shell migration contract
├── tools/
│   ├── measure-teddy-system.sh    # Runtime measurement snapshot
│   ├── verify-iso.sh              # ISO size, checksum, and metadata checks
│   ├── test-alongside.sh          # Disk-safety tests on scratch GPT disks (needs root)
│   └── check-consistency.sh       # Version, brand, encoding, and app-registration checks
├── tests/                         # Component, system-bridge, and installer-flow tests
├── docs/
│   ├── DEVELOPMENT.md
│   ├── TEDDY-V2.1-IMPLEMENTATION.md
│   └── TEDDY-V2.2-SYSTEM-FEATURES.md
├── LICENSE
└── README.md
```

## Roadmap

### Version 2.1 foundation

- [x] Three user modes: Simple, Advanced, and Care
- [x] Offline Teddy Help and local editor assistance
- [x] Document backup and restore foundation
- [x] Salted password hashing for newly created users
- [x] Safer rootfs packaging and successful ISO pipeline
- [x] Separate quality workflow and source checks
- [x] Bryt Ma Tech UG branding across the desktop and release metadata
- [x] Performance and ISO measurement tools
- [ ] QEMU boot test in CI
- [ ] Full VirtualBox/QEMU installation validation report

### Version 2.2 progress (in development, `2.2.0-dev`)

- [x] Browser, Clock, and Software Center applications
- [x] Fingerprint enrolment (fprintd) and keyboard/mouse settings that persist across logins
- [x] Install alongside Windows with safety checks and automatic rollback (tested on scratch disks)
- [x] One version source, one brand name, and CI consistency checks
- [ ] Validate install-alongside in a UEFI VM and on real hardware
- [ ] Facial recognition (no safe, maintained option identified yet)

### Version 2.2 direction

- [ ] Complete Care Mode with text scaling, high contrast, keyboard navigation, captions, and optional speech
- [ ] Task-oriented Simple Mode flows for Wi-Fi, files, photos, updates, and recovery
- [ ] Teddy Guardian version history, checksums, restore points, and undo
- [ ] Native GTK4/Rust shell prototype
- [ ] Safe update preview and rollback implementation
- [ ] Base-image package reduction with published RAM and boot measurements
- [ ] Optional CPU-only local intelligence module with strict permissions
- [ ] Hardware compatibility matrix and signed release checksums

## Contributing

Contributions are welcome. Please open an issue before a large change so the design, accessibility impact, security implications, and resource cost can be discussed. New features should work without external AI, avoid unnecessary background services, preserve recovery paths, and include a test or measurement where appropriate.

## License

Teddy OS is released under the MIT License. See [`LICENSE`](LICENSE).

<div align="center">

**Teddy OS — simple by design, protective by default**  
**Built by Bryt Ma Tech UG · Uganda**

</div>
