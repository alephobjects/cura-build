function build_cbd(){
  revision=$CBD_GIT_REVISION

  CMAKE_ARGS=""

  if [ ! -z "$CBD_BUILD_MARLIN" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DBUILD_MARLIN_FIRMWARES=$CBD_BUILD_MARLIN"
  fi

  if [ ! -z "$CBD_URANIUM" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DPACK_URANIUM=$CBD_URANIUM"
  fi

  if [ ! -z "$CBD_CURA_I18N" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DPACK_CURA_I18N=$CBD_CURA_I18N"
  fi

  if [ ! -z "$CBD_PACK_FIRMWARE" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DPACK_FIRMWARE=$CBD_PACK_FIRMWARE"
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
  echo $CMAKE_ARGS
  cmake $CMAKE_ARGS ..
  make package
  cp *.deb /out/
}
