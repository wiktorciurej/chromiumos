# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

ETYPE="headers"
H_SUPPORTEDARCH="alpha amd64 arc arm arm64 avr32 cris frv hexagon hppa ia64 m32r m68k metag microblaze mips mn10300 nios2 openrisc ppc ppc64 riscv s390 score sh sparc x86 xtensa"
inherit kernel-2 toolchain-funcs
detect_version

PATCH_PV=${PV} # to ease testing new versions against not existing patches
PATCH_VER="1"
SRC_URI="${KERNEL_URI}
	${PATCH_VER:+mirror://gentoo/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}
	${PATCH_VER:+https://dev.gentoo.org/~slyfox/distfiles/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}
"

KEYWORDS="~alpha amd64 arm ~arm64 hppa ia64 ~m68k ~mips ppc ppc64 ~riscv s390 sparc x86 ~amd64-linux ~x86-linux"

DEPEND="app-arch/xz-utils
	dev-lang/perl"
RDEPEND=""

S=${WORKDIR}/linux-${PV}

#
# NOTE: All the patches must be applicable using patch -p1.
#
PATCHES=(
	"${FILESDIR}/0001-CHROMIUM-media-headers-Import-V4L2-headers-from-Chro.patch"
	"${FILESDIR}/0002-CHROMIUM-v4l-Add-VP8-low-level-decoder-API-controls.patch"
	"${FILESDIR}/0003-CHROMIUM-v4l-Add-VP9-low-level-decoder-API-controls.patch"
	"${FILESDIR}/0004-CHROMIUM-v4l-Add-V4L2_CID_MPEG_VIDEO_H264_SPS_PPS_BE.patch"
	"${FILESDIR}/0005-FROMLIST-media-videodev2.h-add-IPU3-raw10-color.patch"
	"${FILESDIR}/0006-FROMLIST-videodev2.h-add-IPU3-meta-buffer-format.patch"
	"${FILESDIR}/0007-CHROMIUM-media-uapi-Add-Intel-IPU3-UAPI-definitions.patch"
	"${FILESDIR}/0008-CHROMIUM-virtwl-add-virtwl-driver.patch"
	"${FILESDIR}/0009-FROMLIST-media-rkisp1-Add-user-space-ABI-definitions.patch"
	"${FILESDIR}/0010-FROMLIST-media-videodev2.h-v4l2-ioctl-add-rkisp1-met.patch"
	"${FILESDIR}/0011-BACKPORT-FROMLIST-media-Add-JPEG_RAW-format.patch"
	"${FILESDIR}/0012-BACKPORT-FROMLIST-media-Add-controls-for-jpeg-quanti.patch"
	"${FILESDIR}/0013-UPSTREAM-media-pixfmt-Add-H264-Slice-format.patch"
	"${FILESDIR}/0014-BACKPORT-FROMLIST-media-uapi-Add-VP8-stateless-decod.patch"
	"${FILESDIR}/0015-FROMLIST-media-pixfmt-Add-Mediatek-ISP-P1-image-meta.patch"
	"${FILESDIR}/0016-FROMGIT-Input-add-privacy-screen-toggle-keycode.patch"
)

src_unpack() {
	unpack ${A}
}

src_prepare() {
	[[ -n ${PATCH_VER} ]] && eapply "${WORKDIR}"/${PATCH_PV}/*.patch

	default
}

src_install() {
	kernel-2_src_install

	# hrm, build system sucks
	find "${ED}" '(' -name '.install' -o -name '*.cmd' ')' -delete
	find "${ED}" -depth -type d -delete 2>/dev/null
}

src_test() {
	# Make sure no uapi/ include paths are used by accident.
	egrep -r \
		-e '# *include.*["<]uapi/' \
		"${D}" && die "#include uapi/xxx detected"

	einfo "Possible unescaped attribute/type usage"
	egrep -r \
		-e '(^|[[:space:](])(asm|volatile|inline)[[:space:](]' \
		-e '\<([us](8|16|32|64))\>' \
		.

	einfo "Missing linux/types.h include"
	egrep -l -r -e '__[us](8|16|32|64)' "${ED}" | xargs grep -L linux/types.h

	emake ARCH=$(tc-arch-kernel) headers_check
}
