FROM debian:stretch

# General env variables
ENV UNIT="All"
ENV GIT_REVISION="master"
ENV DIST_DIR="."
ENV DEB_VERSION=""
ENV DIST="stretch"

# Arcus env variables
ENV ARCUS_PKG_VERSION=""
ENV ARCUS_GIT_REVISION="master"
ENV ARCUS_GIT_REPO="https://code.alephobjects.com/source/arcus.git"

# Savitar env variables
ENV SAVITAR_PKG_VERSION=""
ENV SAVITAR_GIT_REVISION="master"
ENV SAVITAR_GIT_REPO="https://code.alephobjects.com/source/savitar.git"

# Uranium env variables
ENV URANIUM_PKG_VERSION=""
ENV URANIUM_GIT_REVISION="master"
ENV URANIUM_GIT_REPO="https://code.alephobjects.com/diffusion/U/uranium.git"

# Cura Engine env variables
ENV CURAENGINE_PKG_VERSION=""
ENV CURAENGINE_GIT_REVISION="master"
ENV CURAENGINE_GIT_REPO="https://code.alephobjects.com/diffusion/CTE/cura-engine.git"

# Cura2 env variables
ENV CURA2_PKG_VERSION=""
ENV CURA2_GIT_REVISION="master"
ENV CURA2_GIT_REPO="https://code.alephobjects.com/source/Cura2.git"

ENV CURA2_DEPS_MINIMUM_ARCUS_VERSION="${ARCUS_PKG_VERSION}"
ENV CURA2_DEPS_MINIMUM_SAVITAR_VERSION="${SAVITAR_PKG_VERSION}"
ENV CURA2_DEPS_MINIMUM_URANIUM_VERSION="${URANIUM_PKG_VERSION}"
ENV CURA2_DEPS_MINIMUM_CURAENGINE_VERSION="${CURAENGINE_PKG_VERSION}"

# Python Deps version
ENV CURA2_PYTHON_DEPS_PKG_VERSION="0.1.0"
ENV MINIMUM_CURA2_PYTHON_DEPS_PKG_VERSION="0.1.0"

RUN apt-get -qq update && apt-get install -y \
            curl \
            build-essential \
            cmake \
            curl \
            debmake \
            dpkg-dev \
            gfortran \
            git \
            protobuf-compiler \
            libprotobuf-dev \
            libprotoc-dev \
            python3 \
            python3-dev \
            python3-protobuf \
            python3-pip \
            python3-sip-dev \
            rpm \
            sip-dev \
            gfortran \
            libgl1-mesa-dev \
            libx11-dev \
            libxcb1-dev \
            mesa-common-dev \
            pkg-config \
            python3 \
            python3-dev \
            python3-numpy \
            python3-opengl \
            python3-pyqt5 \
            python3-pyqt5.qtopengl \
            python3-pyqt5.qtquick \
            python3-pyqt5.qtsvg \
            python3-serial \
            python3-setuptools \
            qml-module-qtquick-controls \
            qml-module-qtquick-dialogs \
            qml-module-qtquick-layouts \
            qml-module-qtquick-window2 \
            qml-module-qtquick2 \
            x11proto-composite-dev \
            x11proto-core-dev \
            x11proto-damage-dev \
            x11proto-dri2-dev \
            x11proto-fixes-dev \
            x11proto-gl-dev \
            x11proto-input-dev \
            x11proto-kb-dev \
            x11proto-randr-dev \
            x11proto-record-dev \
            x11proto-render-dev \
            x11proto-xext-dev \
            x11proto-xf86vidmode-dev \
            x11proto-xinerama-dev && \
            rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install SIP cx_freeze

WORKDIR /Cura2build

RUN mkdir -p "/Cura2build/build" && \
    mkdir /out && \
    mkdir -p /Cura2build/config/savitar && \
    mkdir -p /Cura2build/config/cura2 && \
    mkdir -p /Cura2build/config/xenial_python_deps/DEBIAN && \
    mkdir -p /Cura2build/scripts && \
    mkdir -p /Cura2build/config/cura-engine

COPY scripts ./scripts
COPY config ./config

RUN chmod +x ./scripts/build.sh

CMD ["/bin/bash", "-c", "/Cura2build/scripts/build.sh \"$UNIT\" \"$GIT_REVISION\" \"$DEB_VERSION\" \"/Cura2build\" \"$DIST\""]
