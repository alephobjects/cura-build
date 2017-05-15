EAPI=6

PYTHON_COMPAT=( python3_{4,5} )
inherit cmake-utils git-r3 python-single-r1

DESCRIPTION="A Python framework for building 3D printing related applications"
HOMEPAGE="https://code.alephobjects.com/diffusion/U/"
EGIT_REPO_URI="https://code.alephobjects.com/diffusion/U/uranium.git"
EGIT_BRANCH="devel"
KEYWORDS="~amd64 ~x86"

LICENSE="AGPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc test"

RDEPEND="${PYTHON_DEPS}
	~dev-libs/libarcus-${PV}:*[${PYTHON_USEDEP}]
	dev-python/PyQt5[${PYTHON_USEDEP},declarative,network,svg]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-qt/qtdeclarative:5
	dev-qt/qtquickcontrols:5"
DEPEND="${RDEPEND}
	sys-devel/gettext
	doc? ( app-doc/doxygen )
	test? ( dev-python/pytest[${PYTHON_USEDEP}] )"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"
DOCS=( README.md )

src_configure() {
	local mycmakeargs=(
		-DPYTHON_SITE_PACKAGES_DIR="$(python_get_sitedir)" )
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
	if use doc; then
		cmake-utils_src_compile doc
		DOCS+=( html )
	fi
}

src_test() {
	emake -C "${BUILD_DIR}" tests
}

src_install() {
	enable_cmake-utils_src_install
	python_optimize "${D}usr/$(get_libdir)"
}
