EAPI="6"

inherit cmake-utils eutils git-r3


DESCRIPTION="A 3D model slicing engine for 3D printing"
HOMEPAGE="https://code.alephobjects.com/diffusion/CTE/"
EGIT_REPO_URI="https://code.alephobjects.com/diffusion/CTE/cura-engine.git"
KEYWORDS="~amd64 ~x86"

LICENSE="AGPL-3"
SLOT="0"
IUSE="doc test"

RDEPEND="${PYTHON_DEPS}
	dev-libs/libarcus
	>=dev-libs/protobuf-3"

DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

# S="${WORKDIR}/cura2engine-${PV}/"

src_configure() {
	local mycmakeargs=( "-DBUILD_TESTS=$(usex test ON OFF)" )
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_make
	if use doc; then
		doxygen
		mv docs/html . || die
		find html -name '*.md5' -or -name '*.map' -delete || die
		DOCS+=( html )
	fi
}

#src_install() {
#	dobin build/CuraEngine
#}
