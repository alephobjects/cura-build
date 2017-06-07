function build_fdm_materials () {
  cd /Cura2build/ultimaker
  git clone https://github.com/Ultimaker/fdm_materials.git
  cd fdm_materials/
  mkdir build && cd build
  cmake -DCMAKE_INSTALL_PREFIX=/Cura2build/ultimaker/build/ultimaker-1.0.0/usr ..
  make
  make install
}

function build_cbd () {
  cd /Cura2build/ultimaker
  git clone https://code.alephobjects.com/diffusion/CBD/cura-binary-data.git
  cd cura-binary-data/
  mkdir build && cd build
  cmake -DCMAKE_INSTALL_PREFIX=/Cura2build/ultimaker/build/ultimaker-1.0.0/usr ..
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