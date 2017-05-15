EAPI="6"

PYTHON_COMPAT=( python3_4 python3_5 )
inherit cmake-utils git-r3 fdo-mime gnome2-utils python-single-r1

DESCRIPTION="A 3D model slicing application for 3D printing"
HOMEPAGE="https://code.alephobjects.com/source/Cura2/"
EGIT_REPO_URI="https://code.alephobjects.com/source/Cura2.git"
EGIT_BRANCH="devel"

LICENSE="AGPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+usb"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	dev-libs/libarcus:=[python,${PYTHON_USEDEP}]
	dev-libs/libsavitar:=[python,${PYTHON_USEDEP}]
	dev-python/uranium[${PYTHON_USEDEP}]
	sci-libs/scipy[${PYTHON_USEDEP}]
	usb? ( dev-python/pyserial[${PYTHON_USEDEP}] )
	dev-python/zeroconf[${PYTHON_USEDEP}]
	media-gfx/curaengine"
DEPEND="${RDEPEND}
	sys-devel/gettext"

src_configure() {
	local mycmakeargs=(
		-DPYTHON_SITE_PACKAGES_DIR="$(python_get_sitedir)" )
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	cmake-utils_src_install
	doicon icons/*.png
	python_optimize "${D}${get_libdir}"
}

pkg_preinst() {
    gnome2_icon_savelist
}

pkg_postinst() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}
