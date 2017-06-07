function build_cbd(){
  revision=$CBD_GIT_REVISION

  cd /Cura2build
  if [ ! -d "build/cura-binary-data" ]; then
    git clone $CBD_GIT_REPO cura-binary-data
    cd cura-binary-data
    git checkout -f $revision
  else
    cd build/cura-binary-data
  fi

  # build Marlin firmware
  echo "Building Marlin firmware"

  ./build-marlin-firmwares.sh

  echo "Marlin firmware build"
  if [ ! -d build ]; then
    mkdir build
  fi
  cd build

  cmake ..

  make package
  cp *.deb /out/
}
