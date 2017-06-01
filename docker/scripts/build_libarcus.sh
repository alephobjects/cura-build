function build_libarcus () {
  revision=$ARCUS_GIT_REVISION
  output=$2
  version=$3
  prefix_dir="$output/libarcus-$version"


  CMAKE_ARGS=""

  if [ ! -z "$ARCUS_PKG_VERSION" ]; then
    CMAKE_ARGS="-DCPACK_PACKAGE_VERSION=$ARCUS_PKG_VERSION "
  fi



  cd /Cura2build

  if [ ! -d "build/arcus" ]; then
    git clone "$ARCUS_GIT_REPO"
    cd arcus
    git checkout -f $revision
  else
    cd build/arcus
  fi

  #sed -i 's/protobuf/python3-protobuf/' CPackConfig.cmake

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
