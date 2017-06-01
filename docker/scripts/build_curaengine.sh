function patch_curaengine(){
  patch_file=$1
  if [ -e "$patch_file" ]; then
    echo "Patching Cura Engine with file: $patch_file"
    git apply "$patch_file"
  fi
}

function build_curaengine () {
  revision=$CURAENGINE_GIT_REVISION
  output=$2
  version=$3
  prefix_dir="$output/curaengine-$version"

  CMAKE_ARGS=""

  if [ ! -z "$CURAENGINE_PKG_VERSION" ]; then
    CMAKE_ARGS="-DCPACK_PACKAGE_VERSION=$CURAENGINE_PKG_VERSION "
  fi

  cd /Cura2build

  if [ ! -d "build/cura-engine" ]; then
    git clone "$CURAENGINE_GIT_REPO"
    cd cura-engine
    git checkout -f $revision
    #patch_curaengine "/Cura2build/config/cura-engine/CuraEngine.patch"
  else
    cd build/cura-engine
    #patch_curaengine "/Cura2build/config/cura-engine/CuraEngine.patch"
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
