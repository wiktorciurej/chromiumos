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

#### Patching `chromeos-base/verity`
You need to modify permissions to apply patches.

Edit `../../chroot/etc/sandbox.conf` and add

```bash
# Verity patches
SANDBOX_WRITE="/mnt/host/source/src/platform/verity/"
```

### Build Packages

```bash
./build_packages --board=${BOARD} --autosetgov (--nouse_any_chrome)
```

To skip time consuming build of `chromeos-base/chromeos-chrome`, omit `--nouse_any_chrome` parameter.
Keep in mind that binary package might be missing some features, especially `chrome_media` extensions.

#### Warning!
Building `chromeos-base/chromeos-chrome` on 8-thread Xeon processor takes about **13-14 hours** and requires almost **40 GB**
of memory. Don't try this without swapfile prepared.

#### Build optimized packages

Instead of using generic binary packages, you can build all packages from sources. With compiler flags
optimized for your hardware, binaries should work faster on your machine. Keep in mind that optimized binary
packages have limited compatibility and won't work on processors older than specified.

Main compiler flag is `march` which selects processor family and it's features. Some packages also use
`CPU_FLAGS_X86` variable, which defines instruction sets supported by CPU.

For more information, check official Gentoo Wiki sites: [Safe_CFLAGS](https://wiki.gentoo.org/wiki/Safe_CFLAGS) and
[CPU_FLAGS_X86](https://wiki.gentoo.org/wiki/CPU_FLAGS_X86).

To build all packages from sources run
```bash
./build_packages --board=${BOARD} --autosetgov --nousepkg --skip_chroot_upgrade --skip_toolchain_update
```

### Build Image

```bash
export BOARD=amd64-wc
./build_image --board=${BOARD} --noenable_rootfs_verification dev --disk_layout 2gb-rootfs-updatable
```

## Other hacks

### Kernel patches

Add your patches to `sys-kernel/chromeos-kernel-5_4/files`

## Change log

### 12/04/2020

* Enable compiler optimizations.

### 10/04/2020

* Enable touchscreen features.
* Update kernel config.

### 08/04/2020

* Update sys-kernel/linux-headers patches.

### 04/04/2020

* Add patches for failing net-wireless/bluez, net-dns/dnsmasq and chromeos-base/verity.
* Backport platform/x86: touchscreen_dmi from mainline Kernel
* Add gsl-firmware for Silead touchscreens from [onitake](https://github.com/onitake/gsl-firmware) repository

### 02/04/2020

* Rebase to official release 82
* Added sse3 to CPU_FLAGS_X86
* Added sys-kernel/linux-headers-5.4 ebuild
* Update Kernel config

### 26/03/2020

* Rebase to official release 80
* Kernel updated to version 5.4
* rtlwifi modules enabled in kernel instead of separate ebuilds
* ebuilds update

### 09/12/2019

* Kernel updated to version 4.19
* ebuilds update
