<!-- cSpell:ignore brcm, realtek, setup, chromiumos, eclass, cros, workon, chromeos, auserver, devserver, noenable, rootfs, updatable, backlight -->

# General info
This repo is a fork of magnificent work made by [arnoldthebat](https://github.com/arnoldthebat) and it's mainly focused on preparing ChromiumOS builds with support for cheap touchscreen netbooks.

# ChromiumOS

Chromium OS is an open-source project that aims to build an operating system that provides a fast, simple, and more secure computing experience for people who spend most of their time on the web.

Clone this repo to your overlay name in your repo/src/overlays

## Setup

```bash
sed -i 's/ALL_BOARDS=(/ALL_BOARDS=(\n amd64-wc\n/' ${HOME}/chromiumos/src/third_party/chromiumos-overlay/eclass/cros-board.eclass

export BOARD=amd64-wc
setup_board --board=${BOARD}
cros_workon --board=${BOARD} start sys-kernel/chromeos-kernel-5_4
```

Running from outside cros_sdk:

```bash
export BOARD=amd64-wc
cd ${HOME}/chromiumos
cros_sdk -- "./setup_board" "--board=${BOARD}"
cros_sdk -- "cros_workon" "--board=${BOARD}" "start" "sys-kernel/chromeos-kernel-5_4"
```

### Build Packages

```bash
./build_packages --board=${BOARD} --autosetgov --nouse_any_chrome
```

### Build Image

```bash
export BOARD=amd64-wc
./build_image --board=${BOARD} --noenable_rootfs_verification dev --disk_layout 2gb-rootfs-updatable
```

## Other hacks

### Kernel patches

Add to File: ../../chroot/etc/sandbox.conf

```bash
# Needed for kernel patches
SANDBOX_WRITE="/mnt/host/source/src/third_party/kernel/v5.4/"
```

### Change Log 26/03/2020

* Rebase to official release 80
* Kernel updated to version 5.4
* rtlwifi modules enabled in kernel instead of separate ebuilds
* ebuilds update

### Change Log 09/12/19

* Kernel updated to version 4.19
* ebuilds update
