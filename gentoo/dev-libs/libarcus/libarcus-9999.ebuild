EAPI=6

PYTHON_COMPAT=( python3_4 python3_5 )
inherit cmake-utils python-single-r1 git-r3

MY_PN="libArcus"

DESCRIPTION="This library facilitates communication between Cura and its backend"
HOMEPAGE="https://code.alephobjects.com/source/arcus/"
EGIT_REPO_URI="https://code.alephobjects.com/source/arcus.git"
KEYWORDS="~amd64 ~x86"

LICENSE="AGPL-3+"
SLOT="0/2"
IUSE="examples python static-libs"
KEYWORDS="~amd64 ~x86"

RDEPEND="${PYTHON_DEPS}
	dev-python/sip[${PYTHON_USEDEP}]
	>=dev-libs/protobuf-3:=
	>=dev-python/protobuf-python-3:*[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_PYTHON=$(usex python ON OFF)
		-DBUILD_EXAMPLES=$(usex examples ON OFF)
		-DBUILD_STATIC=$(usex static-libs ON OFF)
	)
	use python && mycmakeargs+=( -DPYTHON_SITE_PACKAGES_DIR="$(python_get_sitedir)" )
	cmake-utils_src_configure
}
