# cura-build

This repository contains build scripts used to build Cura and all dependencies from scratch.

## OS X

1. Install latest version of Xcode.
    * You may also need to run ```xcode-select --install``` for some XCode commands to be available from the command line.
2. Install [homebrew](http://brew.sh/).
3. Install CMake (```brew install cmake```).
4. On Mac OS X > 10.10, run these commands (needed to build Python packaging libraries):
```
brew update
brew install openssl
brew link openssl --force
```
5. Because Fortran is necessary: *brew install gcc* (Fortran used to be a separate installation but not anymore.  Building gcc can take over 6 hours depending on your computer.)
6. You may need to run the following to build Qt:
```
cd /Applications/Xcode.app/Contents/Developer/usr/bin/
sudo ln -s xcodebuild xcrun
```
7. Run these commands from the CuraBuild directory:
```
mkdir build
cd build
cmake -DMINIMUM_PYTHON_VERSION=3.4.0 ..
make
```

To debug Cura.app, you need the Console open (```open -a Console```) to see stdout and stderr.  You can filter the visible events to "Cura" in the Console Search bar.

## Windows

On Windows, the following dependencies are needed for building( not all for 32-bit builds ):

* **git for windows** (https://git-for-windows.github.io/)
  * The `git` command should be available on your `%PATH%`. Make sure that the `cmd` directory in the git for windows installation directory is on the `%PATH%` and *not* its `bin` directory, otherwise mingw32 will complain about `sh.exe` being on the path.
* **CMake** (http://www.cmake.org/)
  * Once CMake is installed make sure it is available on your `%PATH%`. Check this by running `cmake --version` in the Windows console.
* **MinGW-W64** = 5.3.0 (https://sourceforge.net/projects/mingw-w64/)
  * Once installed, its `bin` directory should be available on your `%PATH%`. Test this by running `mingw32-make --version` in the Windows console.
  * MinGW can be installed on different ways, but these were tested (without guarentees):
    * MinGW w64 installer (32-/64bit): Install the correct target architecture and make sure you choose:
      * Version := 5.3.0
      * Architecture := i686 (here for 32bit)
      * Threads := posix
      * Exception := dwarf
      * Build revision := 0
* **Python** = 3.5.2 (https://www.python.org/downloads/windows/)
  * Download Python 3.5.2 - Windows x86 web-based installer
  * Once installed, `root` directory of the installation should be available on your `%PATH%`.
  * This project supports Python 3.5.1 except for a bug in cx_Freeze.  Use Python 3.5.2 if possible.
  * You will need the latest version of pip `python -m pip install -U pip`
* **cx_Freeze**
  * `pip install cx_Freeze`
  * As of 1-26-2017 the latest version of cx_Freeze (5.0.1) does not support Python 3.5.1 without a patch: https://bitbucket.org/anthony_tuininga/cx_freeze/issues/225/cxfreeze-module-dis-has-no-attribute
* **NumPy** (http://www.lfd.uci.edu/~gohlke/pythonlibs/#numpy)
  * __NOTE__: make sure to get the NON-MKL version!
  * __NOTE__: CJ: It looks like this needs MKL, the above link only provides MKL versions, and Ultimaker Cura uses MKL.
* **SciPy** (http://www.lfd.uci.edu/~gohlke/pythonlibs/#scipy)
* **PySerial** from https://pypi.python.org/pypi/pyserial/3.2.1
  * It can be installed via `pip3 install pyserial`
* **Py2Exe** (https://pypi.python.org/pypi/py2exe/0.9.2.0/#downloads)
  * The easiest way to install this is to run the command `pip install py2exe`. The executable `build_exe.exe` should now be in your `<python dir>/Scripts` directory. You may have to add `<python dir>/Scripts` to you `%PATH%`.
* **Numpy-STL** (https://pypi.python.org/pypi/numpy-stl)
  * Also the easiest way to install is via `pip3 install numpy-stl`.
* **Zeroconf** (https://pypi.python.org/pypi/zeroconf)
  * Again the easiest way to install is via `pip3 install zeroconf`.
* **Visual C++ 2015 Build Tools (http://landinghub.visualstudio.com/visual-cpp-build-tools)**:
  Go to "custom installation" and choose:
    * Select features:
      * Windows 10 SDK 10.0.10.240
* **NSIS 3.01** (http://nsis.sourceforge.net/Main_Page)
  * This application is neeeded to create the installer.
  * You'll need to add the path to your NSIS folder to your system path. (You don't need to add NSIS/bin)
  * Be sure to include the Language files in the installation.
* **PyQt 5.7.1**
  * The pip PyQT 5.6 package is missing the needed qml files. PyQT 5.7.1 works. PyQT 5.8.2 is the latest pip package as of this writing
  * and future PyQt pip packages are not guaranteed to work with this project.
  * `pip install pyqt5==5.7.1`
* **SIP**
  * SIP is installed when pip installing PyQT5, the below line is just included for reference.
  * `pip install SIP`

Here's all of the remote pip packages in a single line.  (Run this after installing the manually downloaded scipy and numpy packages)

```
pip install pyqt5==5.7.1 py2exe cx_Freeze zeroconf numpy-stl
```

Make sure these dependencies are available from your path.

For 32-bit builds:

* There is no need to install the following packages: cx_Freeze, NumPy, SciPy, PySerial, Py2Exe, Numpy-STL, Zeroconf, PyQt and SIP.
* They will be installed when mingw32-make is run.

```shell
REM 32-bit
mkdir build-32
cd build-32
..\env_win32.bat
cmake -G "MinGW Makefiles" ..
mingw32-make package
```

For 64-bit builds:

* PyQt 5.4 (https://riverbankcomputing.com/software/pyqt/download5, Building PyQt currently fails using MinGW 64-bit)
    * CJ: Not sure why this is only in 64-bit instructions because the build scripts require PyQt for 32-bit as well and this project seems to be built upon PyQt.
* Install protobuf.wheel found in cura-build-binaries (TODO: create cura-build-binaries repo)
  * This step may not be needed.
* Create empty ```__init__.py``` in c:\Python34\Lib\site-packages\google (TODO: make it part of the proto.wheel installation)
  * This step may not be needed.

```shell
REM 64-bit
mkdir build-64
cd build-64
cmake -G "MinGW Makefiles" -DBUILD_64BIT=ON -DBUILD_PYSERIAL=0FF ..
mingw32-make
mingw32-make package
```

Before make package - copy arduino to cura-build/
  * This step may not be needed.  The arduino folder is already in the inst folder.

## Ubuntu/Linux

cura-build can build Ubuntu/Debian packages of Cura.

* For Stretch (needed for initial setup):
```shell
apt-get install libsm-dev libxi-dev libfontconfig1-dev libbsd-dev libxdmcp-dev libxcb1-dev libgl1-mesa-dev libgcrypt20-dev liblz4-dev liblzma-dev libselinux1-dev libsystemd-dev libdbus-1-dev libstdc++-6-dev libglib2.0-dev libc6-dev libssl1.0-dev libtinfo-dev libreadline-dev libharfbuzz-dev libxkbcommon-dev gfortran gcc uuid-dev git wget curl cmake build-essential


git clone https://code.alephobjects.com/source/Cura2build.git

cd Cura2build

mkdir build

./build_deb_package.sh
```

* One then can run CuraLE directly from build:
```shell
cd build/dist; ./cura-lulzbot
```

* In order to rebuild just re-run
```shell
./build_deb_package.sh
```

## CentOS/Linux

cura-build can build CentOS/RHEL packages of Cura.

Dependencies:

* gcc-gfortran
* python34.x86_64
* python34-devel.x86_64
* python34-numpy.x86_64
* pyserial.noarch
* PyOpenGL.noarch
* python34-setuptools.noarch
* wxPython.x86_64
* libstdc++-static.x86_64
* libstdc++-devel.x86_64
* openssl.x86_64
* openblas-devel.x86_64
* python34-numpy-f2py.x86_64

For Ubuntu 16.04 install zlib1g-dev, libssl-dev, libreadline-dev
sudo apt-get install zlib1g-dev
sudo apt-get install libssl-dev
sudo apt-get install libreadline-dev

To build, make sure these dependencies are installed, then clone this repository and run the following commands from your clone:

```shell
sudo yum install gcc-gfortran python34.x86_64 python34-devel.x86_64 python34-numpy.x86_64 pyserial.noarch PyOpenGL.noarch python34-setuptools.noarch wxPython.x86_64 libstdc++-static.x86_64 libstdc++-devel.x86_64 openssl.x86_64 openblas-devel.x86_64 python34-numpy-f2py.x86_64
```
1. download and install scipy from https://github.com/scipy/scipy/releases be sure to use python 3.4, eg. using sudo python3 setup.py 2. install (version in repository is for python 2.7)
3. download and install CMake from https://cmake.org/download/ and configure CMake to use ssl
4. download and install Qt5 from https://www.qt.io/download/
5. download and install PyQt5 from https://www.riverbankcomputing.com/software/pyqt/download5
6. download and install sip from https://www.riverbankcomputing.com/software/sip/download make sure the verion is 4.18 or newer

Alternative method for installing python at: https://edwards.sdsu.edu/research/installing-python3-4-and-the-scipy-stack-on-centos/ .
Make sure, that the PYTHONPATH can find dist-packages.

```shell
git clone http://github.com/Ultimaker/cura-build.git
cd cura-build
```

```shell
mkdir build
cd build
cmake -DMINIMUM_PYTHON_VERSION=3.4.0 ..
make
make package
```

## Docker

Build the docker images
----------------------

To build the docker images go to the docker file and use the following command:


**To build for Debian Stretch:**

```
cd docker && \
docker build -t <your-tag> -f images/debian/stretch/Dockerfile .
```

**To build for Ubuntu Zesty:**

```
cd docker && \
docker build -t <your-tag> -f images/ubuntu/zesty/Dockerfile .
```

**To build for Ubuntu Xenial:**

```
cd docker && \
docker build -t <your-tag> -f images/ubuntu/xenial/Dockerfile .
```

Docker files and build scripts for Cura LulzBot Edition builds.


Building DEB packages
---------------------

To build DEB package you need to run `keitaro/alephobjects:stretch` docker container. (For Ubuntu Xenial LTS use `keitaro/alephobjects:xenial`)
You can build the packages by running the following command:

```
docker run -e UNIT=<unit-name> -v <host-out-directory>:/out keitaro/alephobjects:stretch
```

Where:
 * `unit-name` is the name of the library you want to build. Possible values are: *libarcus*, *libsavitar*, *pythonuranium*, *curaengine*, *cura2*, *cbd*, *postprocessing_plugin*, *all*. This would build a
 DEB package for Arcus, Savitar, Uranium, Cura Engine, Cura Binary Data, Cura and Cura PostProcessing Plugin respectively. If no UNIT is given, by default would build all packages.
 * `host-out-directory` is the path to a directory where the generated .deb packages will be generated. This parameter is required - you must specify a host directory where the
 packages will be copied over after building in the container. If you want to generate in you working directory just pass `$(pwd)` as parameter.

For instructions on how to build a specific package see bellow.

Tweaking the builds
===================

You can tweak multiple parameters in the build by setting (overriding) ENV variables in the docker container.
These are the available ENV variables that control the builds:


**General**

 * UNIT (default "All") - which unit to build.  Possible values are: *libarcus*, *libsavitar*, *pythonuranium*, *curaengine*, *cura2*, *all*. This would build a
 DEB package for Arcus, Savitar, Uranium, Cura Engine and Cura respectively. If no UNIT is given, by default would build all packages.
 * DIST (default "stretch") - the target distro for which to build the packages. Possible values are *stretch* (for Debian stretch), *zesty* (for Ubuntu Zesty) and *xenial*(for Ubuntu Xenial LTS).


**Arcus env variables**

* ARCUS_PKG_VERSION (default is the version id CPackConfig.cmake) - arcus debian package version.
* ARCUS_GIT_REVISION (default "master") - arcus revision to checkout when building from repository.
* ARCUS_GIT_REPO (default "https://code.alephobjects.com/source/arcus.git") - arcus Git repository URL.


**Savitar env variables**

* SAVITAR_PKG_VERSION (default is the version id CPackConfig.cmake) - savitar debian package version.
* SAVITAR_GIT_REVISION (default "master") - savitar revision to checkout when building from repository.
* SAVITAR_GIT_REPO (default "https://code.alephobjects.com/source/savitar.git") - savitar Git repository URL.


**Uranium env variables**

* URANIUM_PKG_VERSION=""
* URANIUM_GIT_REVISION="master"
* URANIUM_GIT_REPO="https://code.alephobjects.com/diffusion/U/uranium.git"


**Cura Engine env variables**

* CURAENGINE_PKG_VERSION (default is the version id CPackConfig.cmake) - curaengine debian package version.
* CURAENGINE_GIT_REVISION (default "master") - curaengine revision to checkout when building from repository.
* CURAENGINE_GIT_REPO (default "https://code.alephobjects.com/diffusion/CTE/cura-engine.git") - curaengine Git repository URL.


**Cura env variables**

* CURA_LULZBOT_PKG_VERSION (default is the version id CPackConfig.cmake) - cura2 debian package version.
* CURA_LULZBOT_GIT_REVISION (default "master") - cura2 revision to checkout when building from repository.
* CURA_LULZBOT_GIT_REPO (default "https://code.alephobjects.com/source/Cura2.git") - cura2 Git repository URL.


**FDM Material env variables**

* FDM_GIT_REVISION="master"
* FDM_GIT_REPO="https://github.com/Ultimaker/fdm_materials.git"


**Cura Binary Data variables**

* ENV CBD_BUILD_MARLIN (Default "ON") - whether to build and package Marlin firmware files
* ENV CBD_CURA_I18N (Default "ON") - pack internationalization files
* ENV CBD_URANIUM (Default "ON") - pack uranium internationalization files
* ENV CBD_PACK_FIRMWARE (Default "all", available values are "all", "lulzbot", "ultimaker") - pack specific firmware. By default it will pack all firmware. If you pass "ultimaker" it will pack only the firmware provided by Ultimaker. If passed "lulzbot" it will pack the firmware that is not provided by Ultimaker.


**Cura PostProcessing Plugin variables**

 * CURA_LULZBOT_POSTPROCESSING_GIT_REPO (Default https://code.alephobjects.com/source/Cura2-PostProcessing.git) - Cura2 PostProcessing plugin git repository URL.
 * CURA_LULZBOT_POSTPROCESSING_GIT_REVISION (Default master) - which git revision to build
 * CURA_LULZBOT_POSTPROCESSING_VERSION - debian package version


**Dependencies versions management**

* CURA_LULZBOT_DEPS_MINIMUM_ARCUS_VERSION (defaults to ARCUS_PKG_VERSION) - arcus dependency version.
* CURA_LULZBOT_DEPS_MINIMUM_SAVITAR_VERSION (defaults to SAVITAR_PKG_VERSION) - savitar dependency version.
* CURA_LULZBOT_DEPS_MINIMUM_URANIUM_VERSION (defaults to URANIUM_PKG_VERSION) - uranium dependency version.
* CURA_LULZBOT_DEPS_MINIMUM_CURAENGINE_VERSION (defaults to CURAENGINE_PKG_VERSION) - curaengine dependency version.


**Python Deps version**

* CURA_LULZBOT_PYTHON_DEPS_PKG_VERSION (default "0.1.0") - cura-lulzbot-python-deps debian package version.
* MINIMUM_CURA_LULZBOT_PYTHON_DEPS_PKG_VERSION (default "0.1.0") - cura-lulzbot-python-deps dependency version.


Examples
========


**Build all for stretch from local directory**

First make sure you have checked out the source code for all packages (arcus, savitar, uranium, cura-engine, Cura) in a directory of the host - for example: /home/user/build .
Lets say we want the built packages in /tmp/debian-stretch.
```
docker run -ti -e UNIT=all -e DIST=stretch -v /home/user/build:/Cura2build/build -v /tmp/debian-stretch:/out keitaro/alephobjects:stretch
```
After the build is complete, you'll get the packages in /tmp/debian-stretch:
```
$ ls /tmp/debian-stretch
arcus-15.05.91_amd64.deb  cura-lulzbot-2.5.10-Linux.deb  CuraEngine-15.05.90_amd64.deb  savitar-15.05.91_amd64.deb  uranium-15.05.93-Linux.deb
```


**Building for Ubuntu Xenial**

This build generates more packages (also builds the required packages that are not available out of the box on Ubuntu Xenial LTS).
To build for xenial, you must use the **xenial** tag of the docker container.

Assuming similar setup as the previous example:

```
docker run -ti -e UNIT=all -e DIST=xenial -v /home/user/build:/Cura2build/build -v /tmp/ubuntu-xenial:/out keitaro/alephobjects:xenial
```

Then we'll get the following packages in /tmp/ubuntu-xenial:
```
$ ls /tmp/ubuntu-xenial
arcus-15.05.91_amd64.deb  cura-lulzbot-2.5.10-Linux.deb  cura-lulzbot-python-deps-0.1.0.deb  CuraEngine-15.05.90_amd64.deb  protobuf-3.3.0.deb  savitar-15.05.91_amd64.deb  uranium-15.05.93-Linux.deb
```

Building Arcus
=============

To build Arcus run the following command:

```
docker run -e UNIT=libarcus -e -v $(pwd):/out keitaro/alephobjects:stretch
```

The build will generate a DEB package in your current directory.

Building Savitar
=============

To build Savitar run the following command:

```
docker run -e UNIT=libsavitar -v $(pwd):/out keitaro/alephobjects:stretch
```

The build will generate a DEB package in your current directory.

Building Uranium
=============

To build Uranium run the following command:

```
docker run -e UNIT=pythonuranium -v $(pwd):/out keitaro/alephobjects:stretch
```

The build will generate a DEB package in your current directory.

Building Cura2Engine
=============

To build Cura2Engine run the following command:

```
docker run -e UNIT=curaengine -v $(pwd):/out keitaro/alephobjects:stretch
```

The build will generate a DEB package in your current directory.

Building Cura
=============

To build Cura run the following command:

```
docker run -e UNIT=cura-lulzbot -v $(pwd):/out keitaro/alephobjects:stretch
```

The build will generate a DEB package in your current directory.


Building Ultimaker
=============

Ultimaker contains FDM Material and Ultimaker firmware packages

To build Ultimaker run the following command:

```
docker run -e UNIT=ultimaker -v $(pwd):/out keitaro/alephobjects:stretch
```
The build will generate a DEB package in your current directory.


Building Cura Binary Data
=========================

To build Cura2 Binary Data run the following command:

```
docker run -e UNIT=cbd -v $(pwd):/out keitaro/alephobjects:stretch
```

The build will generate a DEB package in your current directory.


Building Cura2 PostProcessing plugin
=========================

To build Cura PostProcessing plugin run the following command:

```
docker run -e UNIT=postprocessing_plugin -v $(pwd):/out keitaro/alephobjects:stretch
```

The build will generate a DEB package in your current directory.


Building local code
=============

To build local code for specific package run the following command:

```
docker run -e UNIT=(libarcus|libsavitar|pythonuranium|curaengine|cura-lulzbot) -v $(pwd):/out -v $(pwd):/Cura2build/build keitaro/alephobjects:stretch
```

In your current directory you must have cloned the package that you want to build.
