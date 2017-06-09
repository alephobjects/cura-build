function build_fdm_materials () {
  revision=$FDM_GIT_REVISION

  cd /Cura2build/ultimaker
  git clone $FDM_GIT_REPO fdm_materials
  cd fdm_materials/
  git checkout -f $revision
  mkdir build && cd build
  cmake -DCMAKE_INSTALL_PREFIX=/Cura2build/ultimaker/build/ultimaker-1.0.0/usr ..
  make
  make install
}

function build_cbd () {
  revision=$CBD_GIT_REVISION

  CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=/Cura2build/ultimaker/build/ultimaker-1.0.0/usr"

  if [ ! -z "$CBD_BUILD_MARLIN" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DBUILD_MARLIN_FIRMWARES=$CBD_BUILD_MARLIN"
  fi

  cd /Cura2build

  if [ ! -d "build/cura-binary-data" ]; then
    cd ultimaker
    git clone $CBD_GIT_REPO cura-binary-data
    cd cura-binary-data/
    git checkout -f $revision
  else
    cd build/cura-binary-data
  fi

  mkdir build && cd build
  cmake $CMAKE_ARGS ..
  make
  make install
}

function build_ultimaker() {
  build_fdm_materials
  build_cbd
  
  # remove lulzbot firmware
  cd ../..
  find /Cura2build/ultimaker/build/ultimaker-1.0.0/usr \
       -regextype posix-extended -regex '.*(TAZ|Mini-Single).*\.hex'| xargs rm

  # remove translation files     
  rm -rf \
    /Cura2build/ultimaker/build/ultimaker-1.0.0/usr/share/uranium \
    /Cura2build/ultimaker/build/ultimaker-1.0.0/usr/share/cura/resources/i18n

  # create debian package
  mkdir -p build/ultimaker-1.0.0/DEBIAN
  cp /Cura2build/config/ultimaker/DEBIAN/control build/ultimaker-1.0.0/DEBIAN/
  dpkg-deb --build build/ultimaker-1.0.0
  cp build/*.deb /out/
}