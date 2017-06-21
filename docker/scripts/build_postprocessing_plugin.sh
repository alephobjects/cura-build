function build_postprocessing_plugin(){

  CMAKE_ARGS=""

  if [ ! -z "$CURA2_POSTPROCESSING_VERSION" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCPACK_PACKAGE_VERSION=$CURA2_POSTPROCESSING_VERSION"
  fi

  cd "/Cura2build"

  if [ -d "/Cura2build/build/Cura2-PostProcessing" ]; then
    cd "/Cura2build/build/Cura2-PostProcessing"
  else
    git clone "$CURA2_POSTPROCESSING_GIT_REPO" "Cura2-PostProcessing"
    cd "Cura2-PostProcessing"
    git checkout -f "$CURA2_POSTPROCESSING_GIT_REVISION"
  fi

  mkdir build && cd build
  cmake $CMAKE_ARGS ..
  make package
  cp *.deb /out
}
