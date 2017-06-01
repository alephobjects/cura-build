function build_libsavitar () {
  revision=$SAVITAR_GIT_REVISION
  output=$2
  version=$3
  prefix_dir="$output/libsavitar-$version"


  CMAKE_ARGS=""

  if [ ! -z "$SAVITAR_PKG_VERSION" ]; then
    CMAKE_ARGS="-DCPACK_PACKAGE_VERSION=$SAVITAR_PKG_VERSION "
  fi

  cd /Cura2build

  if [ ! -d "build/savitar" ]; then
    git clone "$SAVITAR_GIT_REPO"
    cd savitar
    git checkout -f $revision
  else
    cd build/savitar
  fi

  #mv /Cura2build/config/savitar/CPackConfig.cmake ./
  #sed -i 's/# include(CPackConfig.cmake)/include(CPackConfig.cmake)/' CMakeLists.txt

  if [ ! -d "build" ]; then
    mkdir build
  fi

  cd build
  cmake $CMAKE_ARGS ..
  make
  make install
  cpack ..
  cp *.deb /out/
}
