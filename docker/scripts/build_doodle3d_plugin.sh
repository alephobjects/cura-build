function build_doodle3d_plugin(){

  CMAKE_ARGS=""

  if [ ! -z "$CURA2_DOODLE3D_VERSION" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCPACK_PACKAGE_VERSION=$CURA2_DOODLE3D_VERSION"
  fi

  cd "/Cura2build"

  if [ -d "/Cura2build/build/Doodle3D-cura-plugin" ]; then
    cd "/Cura2build/build/Doodle3D-cura-plugin"
  else
    git clone "$CURA2_DOODLE3D_GIT_REPO" "Doodle3D-cura-plugin"
    cd "Doodle3D-cura-plugin"
    git checkout -f "$CURA2_DOODLE3D_GIT_REVISION"
  fi

  mkdir build && cd build
  cmake $CMAKE_ARGS ..
  make package
  cp *.deb /out
}
