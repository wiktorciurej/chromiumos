# Copyright 2020 Wiktor Ciurej. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
EGIT_REPO_URI="https://github.com/onitake/gsl-firmware"

# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit eutils git-2

HOMEPAGE="https://github.com/onitake/gsl-firmware"
DESCRIPTION="Firmware repository for Silead touchscreen controllers"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"

src_install() {
	insinto /lib/firmware

	doins -r "${WORKDIR}/${P}/firmware/linux/silead/"
}