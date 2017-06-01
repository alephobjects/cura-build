function build_protobuf () {
  cd /Cura2build/protobuf
  mkdir -p build/protobuf-3.3.0/DEBIAN
  cp /Cura2build/config/xenial_protobuf/DEBIAN/control build/protobuf-3.3.0/DEBIAN/

  wget https://github.com/google/protobuf/archive/v3.3.0.tar.gz
  tar xzf v3.3.0.tar.gz
  cd protobuf-3.3.0
  ./autogen.sh
  ./configure --prefix=/Cura2build/protobuf/build/protobuf-3.3.0/opt/cura2
  make -j4
  make install

  cd ..
  dpkg-deb --build build/protobuf-3.3.0
  cp build/*.deb /out/
}
