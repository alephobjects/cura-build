#!/bin/bash
UNIT=$1
GIT_REVISION=$2
DEB_VERSION=$3
BASEDIR=$4
DIST=$5
OUT_DIR=$BASEDIR

source scripts/build_libarcus.sh
source scripts/build_libsavitar.sh
source scripts/build_pythonuranium.sh
source scripts/build_curaengine.sh
source scripts/build_cura2.sh
source scripts/build_ultimaker.sh
source scripts/build_cbd.sh
source scripts/build_postprocessing_plugin.sh
source scripts/build_doodle3d_plugin.sh

if [[ "$DIST" == "xenial" ]]; then
  source scripts/build_protobuf.sh
fi

echo "Building for: $DIST"

case $UNIT in
  "libarcus")
    if [[ "$DIST" == "xenial" ]]; then
      build_protobuf
    fi
    build_libarcus "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
  ;;
  "libsavitar")
    build_libsavitar "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
  ;;
  "pythonuranium")
    if [[ "$DIST" == "xenial" ]]; then
      build_protobuf
      build_pythonuranium "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "ubuntu-xenial"
    else
      build_pythonuranium "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "debian-stretch"
    fi
  ;;
  "curaengine")
    if [[ "$DIST" == "xenial" ]]; then
      build_protobuf
    fi
    build_libarcus "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
    build_curaengine "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
  ;;
  "cura2")
    build_libarcus "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
    build_libsavitar "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"

    if [[ "$DIST" == "xenial" ]]; then
      build_protobuf
      build_pythonuranium "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "ubuntu-xenial"
      build_curaengine "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
      build_cura2_xenial "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "ubuntu-xenial"
    else
      build_pythonuranium "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "debian-stretch"
      build_curaengine "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
      build_cura2 "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "debian-stretch"
    fi
  ;;
  "ultimaker")
    build_ultimaker
  ;;
  "cbd")
    build_cbd "$OUT_DIR"
  ;;
  "postprocessing_plugin")
    build_postprocessing_plugin
  ;;
  "doodle3d_plugin")
    build_doodle3d_plugin
  ;;
  *)
  echo "Build all..."
    build_libarcus "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
    build_libsavitar "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"

    if [[ "$DIST" == "xenial" ]]; then
      build_protobuf
      build_pythonuranium "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "ubuntu-xenial"
      build_curaengine "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
      build_cura2_xenial "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "ubuntu-xenial"
    else
      build_pythonuranium "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "debian-stretch"
      build_curaengine "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION"
      build_cura2 "$GIT_REVISION" "$OUT_DIR" "$DEB_VERSION" "debian-stretch"
    fi

    build_ultimaker
    build_cbd "$OUT_DIR"
    build_postprocessing_plugin
    build_doodle3d_plugin
  ;;
esac
