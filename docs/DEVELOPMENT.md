# Teddy OS - development guide

GitHub is the source of truth. A local copy is disposable: delete it any time, clone again when you need it.

## 1. Get a working copy from nothing (Windows PowerShell)

Install once: Git, Node.js 20 LTS (desktop), Node.js 22 LTS (only for `tests/`), GitHub CLI (`winget install --id GitHub.cli`).

    git clone https://github.com/muhumuza684/teddy-os.git D:\dev\teddy-os
    cd D:\dev\teddy-os
    git config core.autocrlf false          # keep LF line endings
    cd desktop
    npm ci                                   # if npm says the lock file is out of sync, run: npm install
    git checkout -- package-lock.json        # (only after npm install) never commit a lock-file rewrite
    npm run build                            # CI mode: set CI=true to make warnings fail like GitHub does

Windows may refuse to create `node_modules` on the Desktop (file locks). Work in a plain folder such as `D:\dev`.
Set `ELECTRON_SKIP_BINARY_DOWNLOAD=1` to skip the 100 MB Electron download when you only need a build.

## 2. Rules the repository enforces (`bash tools/check-consistency.sh`, runs in CI)

- One version: `desktop/package.json`. The UI, ISO name, `os-release`, and README badge follow it.
- One brand name: "Bryt Ma Tech UG".
- UTF-8 without BOM, LF line endings, no garbled characters, no placeholder URLs.
- Every app listed in a mode is registered in `App.jsx` (APP_META, TASKBAR_APPS, render switch).
- Shell scripts: shebang, `set -euo pipefail`, syntax-checked in `quality.yml`.
- Paths in build scripts are relative to the repository root.

Run the check with Git Bash (`"C:\Program Files\Git\bin\bash.exe" tools/check-consistency.sh`) or on Linux. It needs Node.

## 3. Tests (`tests/`, needs Node 22 or newer)

    cd tests
    npm ci
    sh sync.sh
    npx vitest run                           # component + system-bridge tests (needs a display on Linux: xvfb-run -a ...)

The disk-safety and installer tests build scratch GPT disks and need Linux with root:

    sudo bash tools/test-alongside.sh
    sudo bash tests/install-flow.sh

GitHub runs all of them in the `system-tests` job of "Teddy OS Quality Checks" (reported, not blocking).

## 4. Daily workflow

1. Never push to `main`. Create a branch: `git checkout -b my-change`.
2. Commit, then `git push -u origin my-change`.
3. Open a pull request into `main`. "Teddy OS Quality Checks" runs automatically.
4. To build an ISO from the branch: Actions -> "Build Teddy OS ISO" -> Run workflow -> choose your branch.
5. Merge when the checks are green (and, for installer changes, the VM test below passed). Squash-merge keeps history tidy.
6. Merging into `main` starts the ISO build for `main`.

## 5. What each workflow does

| Workflow | Starts when | Produces |
|---|---|---|
| Teddy OS Quality Checks | pull request into main, push to main, manual | build check, consistency check, shell syntax, system tests |
| Build Teddy OS ISO | push to main, manual (any branch) | artifacts `teddy-os-desktop-build`, `teddy-os-rootfs`, `teddy-os-iso` |

Artifacts expire after GitHub's retention period, so download the ISO when you need it (Actions -> run -> Artifacts).
The ISO is named `teddyos-<version>-x86_64.iso`, where the version comes from `desktop/package.json`.

## 6. Testing the ISO in a virtual machine (do this before merging installer changes)

VirtualBox: New VM -> Linux / Debian 64-bit, 4 GB RAM, 2 CPUs, 32 GB disk.
Settings -> System -> **Enable EFI (special OSes only)** must be ticked: the installer's Windows option needs UEFI.
Settings -> Storage -> attach the ISO. Boot it.

1. Login, all three modes, Browser, Clock, Software Center, Settings (Security, Devices).
2. Install to the empty virtual disk (erase mode) and boot the installed system.
3. For "install alongside Windows", first install Windows into the VM disk, shut Windows down completely, then boot the Teddy ISO and install alongside. Reboot and confirm GRUB lists both systems and both boot.
4. Repeat with Windows hibernated (Fast Startup on): the installer must refuse and leave the disk untouched.
5. Check the GRUB menu text and the `/etc/os-release` version (`2.2.0-dev` style, no `1.0`).

Never test the alongside installer on a real computer before this passes, and back up first.

## 7. Troubleshooting (problems seen while building this)

| Symptom | Cause | Fix |
|---|---|---|
| `npm ci` says lock file out of sync, "Missing: dmg-license" | newer npm vs. the repo lock file | use `npm install`, then `git checkout -- desktop/package-lock.json` |
| `EPERM ... rmdir ... node_modules` | Windows/antivirus locking files (often on Desktop) | work in `D:\dev`; delete folders with `cmd /c rmdir /s /q <folder>` |
| `Recv failure: Connection was reset` on push | network dropped | run the push again; the scripts retry automatically |
| Consistency check says "python3: command not found" | old checker version | update the repo; the checker now needs only Node |
| "System features" job red, `npm install` crash | vitest 5 / jsdom 30 need Node 22 | job runs on Node 22 with `tests/package-lock.json` |
| Script refuses: "uncommitted changes" | an earlier run stopped halfway | `git status`; discard with `git reset --hard HEAD` and `git clean -fd` if they are not yours |
| ISO build stops "No desktop build found" | the desktop job did not produce `desktop/build` | check the "Build Teddy OS Desktop App" job first |

## 8. Disk space

The big folders are `desktop/node_modules` (about 1 GB) and `desktop/build`. Delete the whole working copy when finished
(`cmd /c rmdir /s /q D:\dev\teddy-os`) and clear the npm cache (`npm cache clean --force`). Nothing is lost: it is all on GitHub.
