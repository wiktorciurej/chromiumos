# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

XORG_DOC=doc
XORG_MULTILIB=yes
inherit xorg-2

DESCRIPTION="X.Org XExt protocol headers"

KEYWORDS="*"
#KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE=""

RDEPEND="!<x11-libs/libXext-1.0.99"
DEPEND="${RDEPEND}"

pkg_setup() {
	xorg-2_pkg_setup

	XORG_CONFIGURE_OPTIONS=(
		$(use_with doc xmlto)
		--without-fop
	)
}