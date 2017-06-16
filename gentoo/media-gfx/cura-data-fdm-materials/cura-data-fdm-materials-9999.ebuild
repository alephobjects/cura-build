EAPI="6"

inherit cmake-utils git-r3 fdo-mime gnome2-utils

DESCRIPTION="Ultimaker fdm_materials binary data."
HOMEPAGE="https://github.com/Ultimaker/fdm_materials"
EGIT_REPO_URI="https://github.com/Ultimaker/fdm_materials.git"
EGIT_BRANCH="master"

LICENSE="AGPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="media-gfx/cura"
DEPEND=""

src_configure() {
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	cmake-utils_src_install
}
