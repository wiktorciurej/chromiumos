# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/bluez/bluez-4.99.ebuild,v 1.7 2012/04/15 16:53:41 maekke Exp $

EAPI="7"
# To support choosing between current and next versions, two cros-workon
# projects are declared. During emerge, both project sources are copied to
# their respective destination directories, and one is chosen as the
# "working directory" in src_unpack() below based on bluez-next USE flag.
CROS_WORKON_COMMIT=("11bdb04bfee294c4f306213f039221c54ebf1791" "fe008cb6284b48935783b7c5db6de1a0b47236ef")
CROS_WORKON_TREE=("72e816f37cf7252162a2d2b3c02371fb9a421f7f" "6a0c8722a4755b294a38e72f45242cf26134b36f")
CROS_WORKON_LOCALNAME=("bluez" "bluez-next")
CROS_WORKON_PROJECT=("chromiumos/third_party/bluez" "chromiumos/third_party/bluez")
CROS_WORKON_DESTDIR=("${S}/bluez" "${S}/bluez-next")

inherit autotools multilib eutils systemd udev user libchrome cros-sanitizers cros-workon toolchain-funcs flag-o-matic

DESCRIPTION="Bluetooth Tools and System Daemons for Linux"
HOMEPAGE="http://www.bluez.org/"
#SRC_URI not defined because we get our source locally

LICENSE="GPL-2 LGPL-2.1"
KEYWORDS="*"
IUSE="asan bluez-next cups debug systemd readline bt_deprecated_tools"

CDEPEND="
	>=dev-libs/glib-2.14:2=
	app-arch/bzip2:=
	sys-apps/dbus:=
	virtual/libudev:=
	cups? ( net-print/cups:= )
	readline? ( sys-libs/readline:= )
	chromeos-base/metrics:=
"
DEPEND="${CDEPEND}"

RDEPEND="${CDEPEND}
	!net-wireless/bluez-hcidump
	!net-wireless/bluez-libs
	!net-wireless/bluez-test
	!net-wireless/bluez-utils
"
BDEPEND="${CDEPEND}
	dev-util/pkgconfig:=
	sys-devel/flex:=
"

DOCS=( AUTHORS ChangeLog README )

PATCHES=(
	"${FILESDIR}/0001-tools-Fix-build-after-y2038-changes-in-glibc.patch"
)

src_unpack() {
	cros-workon_src_unpack

	# Setting S has the effect of changing the temporary build directory
	# here onwards. Choose "bluez-next" or "bluez" subdir depending on the
	# USE flag.
	S+="/$(usex bluez-next bluez-next bluez)"
}

src_prepare() {
	default

	eautoreconf

	if use cups; then
		sed -i \
			-e "s:cupsdir = \$(libdir)/cups:cupsdir = $(cups-config --serverbin):" \
			Makefile.tools Makefile.in || die
	fi
}

src_configure() {
	sanitizers-setup-env
	# Workaround a global-buffer-overflow warning in asan build.
	# See crbug.com/748216 for details.
	if use asan; then
		append-flags '-mllvm -asan-globals=0'
	fi

	use readline || export ac_cv_header_readline_readline_h=no

	econf \
		--enable-tools \
		--localstatedir=/var \
		$(use_enable cups) \
		--enable-datafiles \
		$(use_enable debug) \
		--disable-test \
		--enable-library \
		--disable-systemd \
		--disable-obex \
		--enable-sixaxis \
		--disable-network \
		--enable-maintainer-mode \
		$(use_enable bt_deprecated_tools deprecated)
}

src_test() {
	# TODO(armansito): Run unit tests for non-x86 platforms.
	[[ "${ARCH}" == "x86" || "${ARCH}" == "amd64" ]] && \
		emake check VERBOSE=1
}

src_install() {
	# Install command-line tools
	dobin client/bluetoothctl
	dobin monitor/btmon
	dobin tools/btgatt-client
	dobin tools/btgatt-server
	dobin tools/btmgmt
	if ! use bluez-next; then
		# TODO(b/150951215): Remove this fork if possible by deprecating
		# hciconfig and hcitool.
		dobin tools/hciconfig
		dobin tools/hcitool
	fi

	# Install scripts
	dobin "${FILESDIR}/dbus_send_blutooth_class.awk"
	dobin "${FILESDIR}/get_bluetooth_device_class.sh"
	dobin "${FILESDIR}/start_bluetoothd.sh"
	dobin "${FILESDIR}/start_bluetoothlog.sh"

	# Install daemons
	exeinto /usr/libexec/bluetooth
	doexe src/bluetoothd

	# Install development library files
	insinto /usr/include/bluetooth
	doins lib/*.h
	insinto /usr/"$(get_libdir)"/pkgconfig
	doins lib/bluez.pc

	# Install shared library files
	dolib.so lib/.libs/libbluetooth.so
	dolib.so lib/.libs/libbluetooth.so.3
	# TODO(b/152442119): Don't hardcode the version number
	dolib.so lib/.libs/libbluetooth.so.3."$(usex bluez-next 19.2 18.15)"

	# Install plugin library files
	exeinto /usr/"$(get_libdir)"/bluetooth/plugins
	doexe plugins/.libs/sixaxis.so

	# Install init scripts.
	if use systemd; then
		systemd_dounit "${FILESDIR}/bluetoothd.service"
		systemd_enable_service system-services.target bluetoothd.service
		systemd_dotmpfilesd "${FILESDIR}/bluetoothd-directories.conf"
	else
		insinto /etc/init
		newins "${FILESDIR}/${PN}-upstart.conf" bluetoothd.conf
		newins "${FILESDIR}/bluetoothlog-upstart.conf" bluetoothlog.conf
	fi

	# Install D-Bus config
	insinto /etc/dbus-1/system.d
	doins "${FILESDIR}/org.bluez.conf"

	# Install udev files
	exeinto /lib/udev
	doexe tools/hid2hci
	udev_newrules "tools/hid2hci.rules" "97-hid2hci.rules"
	udev_dorules "${FILESDIR}/99-uhid.rules"
	udev_dorules "${FILESDIR}/99-ps3-gamepad.rules"
	udev_dorules "${FILESDIR}/99-bluetooth-quirks.rules"
	udev_dorules "${FILESDIR}/99-bluetooth-suspend-owner.rules"

	# Install the config files.
	insinto "/etc/bluetooth"
	# TODO(b/150951215): Remove the fork once our branch converges with
	# upstream.
	if ! use bluez-next; then
		# TODO(b/152526402): bluez-next should install main.conf after
		# all per-board main.conf files have been removed.
		doins "${S}/src/main_common.conf"
	fi
	doins "${FILESDIR}/input.conf"

	# We don't preserve /var/lib in images, so nuke anything we preseed.
	rm -rf "${D}"/var/lib/bluetooth

	rm "${D}/lib/udev/rules.d/97-bluetooth.rules"

	find "${D}" -name "*.la" -delete
}

pkg_postinst() {
	enewuser "bluetooth" "218"
	enewgroup "bluetooth" "218"

	udev_reload

	if ! has_version "net-dialup/ppp"; then
		elog "To use dial up networking you must install net-dialup/ppp."
	fi

	if [ "$(rc-config list default | grep bluetooth)" = "" ] ; then
		elog "You will need to add bluetooth service to default runlevel"
		elog "for getting your devices detected from startup without needing"
		elog "to reconnect them. For that please run:"
		elog "'rc-update add bluetooth default'"
	fi
}
