EAPI="6"

inherit cmake-utils git-r3 fdo-mime gnome2-utils

DESCRIPTION="Contains binary data for Cura releases, like compiled translations and firmware."
HOMEPAGE="https://code.alephobjects.com/diffusion/CBD/"
EGIT_REPO_URI="https://code.alephobjects.com/diffusion/CBD/cura-binary-data.git"
EGIT_BRANCH="master"

LICENSE="AGPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="media-gfx/cura"
DEPEND=""

src_configure() {
	local mycmakeargs=(
  -DBUILD_MARLIN_FIRMWARES="ON" -DPACK_URANIUM="OFF" -DPACK_CURA_I18N="OFF" -DPACK_FIRMWARE="ultimaker")
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	cmake-utils_src_install
}
