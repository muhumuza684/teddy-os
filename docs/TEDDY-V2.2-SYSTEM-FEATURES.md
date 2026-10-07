# Teddy OS - system features added after v2.1

Status of each item, and exactly what was and was not verified.

| Feature | Where | Verified |
|---|---|---|
| Browser app (Electron `<webview>`) | `desktop/src/apps/Browser.jsx`, `webviewTag: true` in `electron/main.js` | Real Electron under Xvfb loads a page, reports URL/title/history. Live internet not tested. |
| Clock (world, alarm, timer, stopwatch) | `desktop/src/apps/Clock.jsx` | Component tests with fake timers; uses the real notification provider. |
| Software Center (Wine, Docker, fprintd, GIMP, VLC, Codium) | `desktop/src/apps/SoftwareCenter.jsx`, `electron/system-ipc.js` | IPC round trip in real Electron; install streaming tested with a stubbed `pkexec`. A real `apt-get` install is untested. |
| Fingerprint enrollment (fprintd) | Settings -> Security | "No reader / not installed" paths. A real reader is untested. |
| Keyboard repeat and pointer acceleration, persisted at login | Settings -> Devices, `App.jsx` | `xset` called with exact clamped arguments. |
| Install alongside Windows | `iso-builder/lib/alongside*.sh`, `install.sh` | Scratch GPT disks: detection, refusals (hibernation, BitLocker, dirty, full, MBR), rollback, real NTFS shrink, full `install.sh` flow with the heavy steps stubbed. **Not tested on real hardware or with a real GRUB boot.** |
| Dual-boot packages | `iso-builder/build-rootfs.sh` | `bash -n` only; a full ISO build is the next check. |

Care Mode intentionally has no Software Center (reduced distractions).
All new system calls are Linux-only and answer "needs Teddy OS" on other platforms.

## Running the tests (Linux or WSL, root for the disk tests)

    sudo apt-get install -y nodejs npm xvfb x11-xserver-utils gdisk ntfs-3g parted dosfstools mtools
    sudo ./tests/run-all.sh

## Before trusting install-alongside on a real computer

1. Build the ISO in CI and boot it in VirtualBox/QEMU with a **UEFI** VM that has a Windows 10/11 disk image.
2. Run the installer, choose "Install alongside Windows", reboot, confirm the GRUB menu lists Teddy OS and Windows, and that both boot.
3. Repeat with Windows hibernated (Fast Startup on) and confirm the installer refuses and the disk is unchanged.
4. Only then back up a real machine and try it there.
