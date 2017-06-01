function patch_cura2() {
  patch_file=$1

  if [ -e "$patch_file" ]; then
    echo "Patching Cura2 with: $patch_file"
    git apply "$patch_file"
  fi
}

function build_cura2 () {
  revision=$CURA2_GIT_REVISION
  output=$2
  version=$3
  target=$4
  prefix_dir="$output/libarcus-$version"

  if [ -d "/Cura2build/uranium" ]; then
    uranium_dir=/Cura2build/uranium
  else
    uranium_dir=/Cura2build/build/uranium
  fi

  CMAKE_ARGS="-DURANIUM_DIR=$uranium_dir -DDEB_PACKAGE_TARGET_PLATFORM=$target "

  if [ ! -z "$CURA2_PKG_VERSION" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCPACK_PACKAGE_VERSION=$CURA2_PKG_VERSION "
  fi

  if [ ! -z "$CURA2_DEPS_MINIMUM_ARCUS_VERSION" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DMINIMUM_ARCUS_VERSION=$CURA2_DEPS_MINIMUM_ARCUS_VERSION "
  fi

  if [ ! -z "$CURA2_DEPS_MINIMUM_SAVITAR_VERSION" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DMINIMUM_SAVITAR_VERSION=$CURA2_DEPS_MINIMUM_SAVITAR_VERSION "
  fi

  if [ ! -z "$CURA2_DEPS_MINIMUM_URANIUM_VERSION" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DMINIMUM_URANIUM_VERSION=$CURA2_DEPS_MINIMUM_URANIUM_VERSION "
  fi

  if [ ! -z "$CURA2_DEPS_MINIMUM_CURAENGINE_VERSION" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DMINIMUM_CURAENGINE_VERSION=$CURA2_DEPS_MINIMUM_CURAENGINE_VERSION "
  fi



  cd /Cura2build

  if [ ! -d "build/Cura2" ]; then
    git clone "$CURA2_GIT_REPO"
    cd Cura2
    git checkout -f $revision
    #patch_cura2 "/Cura2build/config/cura2/Cura2.patch"
  else
    cd build/Cura2
    #patch_cura2 "/Cura2build/config/cura2/Cura2.patch"
  fi

  #cp /Cura2build/config/cura2/CPackConfig.cmake ./
  #echo "include(CPackConfig.cmake)" >> CMakeLists.txt

  if [ ! -d "build" ]; then
    mkdir build
  fi

  cd build
  echo $CMAKE_ARGS
  cmake $CMAKE_ARGS ..
  make
  make package
  cp *.deb /out/
}


function build_cura2_python_deps(){
  version=$1

  PKG_DIR="./cura2-python-deps-$1"
  PYTHON_PKG_DEST_DIR="./cura2-python-deps-$1/opt/cura2/python3.5/site-packages"

  mkdir -p "$PYTHON_PKG_DEST_DIR"
  mkdir -p "$PKG_DIR/DEBIAN"

  cp /Cura2build/config/xenial_python_deps/DEBIAN/control "$PKG_DIR/DEBIAN/"

  sed -i "s/PYTHON_DEPS_PKG_VERSION/${version}/" "$PKG_DIR/DEBIAN/control"

  pip3 install \
            PyQt5 \
            sip \
            pyserial \
            typing \
            zeroconf \
            appdirs \
            netifaces \
            six \
            --target="$PYTHON_PKG_DEST_DIR"

  dpkg-deb --build "$PKG_DIR"
  cp *.deb /out
}


function build_cura2_xenial(){
  revision=$1
  output=$2
  version=$3
  prefix_dir="$output/libarcus-$version"

  build_cura2_python_deps "${CURA2_PYTHON_DEPS_PKG_VERSION}"
  build_cura2 "$revision" "$output" "$version" "ubuntu-xenial"
}
