function patch_uranium(){
  patch_file=$1
  if [ -e "$patch_file" ]; then
    echo "Patching uranium with file: $patch_file"
    git apply "$patch_file"
  fi
}

function build_pythonuranium () {
  revision=$URANIUM_GIT_REVISION
  output=$2
  version=$3
  target=$4
  prefix_dir="$output/pythonuranium-$version"

  CMAKE_ARGS="-DDEB_PACKAGE_TARGET_PLATFORM=$target -DMINIMUM_CURA2_PYTHON_DEPS_PKG_VERSION=$MINIMUM_CURA2_PYTHON_DEPS_PKG_VERSION"

  if [ ! -z "$URANIUM_PKG_VERSION" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCPACK_PACKAGE_VERSION=$URANIUM_PKG_VERSION "
  fi

  if [ ! -z "$CURA2_DEPS_MINIMUM_ARCUS_VERSION" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DMINIMUM_ARCUS_VERSION=$CURA2_DEPS_MINIMUM_ARCUS_VERSION "
  fi

  cd /Cura2build

  if [ ! -d "build/uranium" ]; then
    git clone "https://code.alephobjects.com/diffusion/U/uranium.git"
    cd uranium
    git checkout -f $revision
    #patch_uranium "/Cura2build/config/uranium/CPackConfig.cmake.patch"
  else
    cd build/uranium
    #patch_uranium "/Cura2build/config/uranium/CPackConfig.cmake.patch"
  fi

  if [ ! -d "build" ]; then
    mkdir build
  fi

  cd build
  echo $CMAKE_ARGS
  cmake $CMAKE_ARGS ..
  make
  make install
  cpack ..
  cp *.deb /out/
}
