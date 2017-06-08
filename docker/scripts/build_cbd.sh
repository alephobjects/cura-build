function build_cbd(){
  revision=$CBD_GIT_REVISION

  CMAKE_ARGS=""

  if [ ! -z "$CBD_BUILD_MARLIN" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DBUILD_MARLIN_FIRMWARES=$CBD_BUILD_MARLIN"
  fi

  cd /Cura2build
  if [ ! -d "build/cura-binary-data" ]; then
    git clone $CBD_GIT_REPO cura-binary-data
    cd cura-binary-data
    git checkout -f $revision
  else
    cd build/cura-binary-data
  fi


  if [ ! -d build ]; then
    mkdir build
  fi
  cd build
  cmake $CMAKE_ARGS ..
  make package
  cp *.deb /out/
}
