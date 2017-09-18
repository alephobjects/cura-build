project(cura-build)

cmake_minimum_required(VERSION 2.8.12)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

include(ExternalProject)
include(GNUInstallDirs)

# Define Options
option(BUILD_PYTHON "Include Python" ON)
option(BUILD_CYTHON "Include Cython" ON)
option(BUILD_QT "Include Qt" ON)
option(BUILD_SIP "Include SIP" ON)
option(BUILD_PYQT "Include PyQt" ON)
option(BUILD_OPENBLAS "Include OpenBLAS" ON)
option(BUILD_NUMPY "Include Numpy" ON)
option(BUILD_SCIPY "Include Scipy" ON)
option(BUILD_SCIPY_LITE "Include Scipy Lite" OFF)
option(BUILD_PYSERIAL "Include PySerial" ON)
option(BUILD_NUMPY_STL "Include Numpy-STL" ON)
option(BUILD_PYTHON_UTILS "Include Python-Utils" ON)
option(BUILD_ZEROCONF "Include python-zeroconf" ON)
option(BUILD_TYPING "Include python-typing" ON)
option(BUILD_SAVITAR "Include Savitar Library" ON)
option(BUILD_APPDIRS "Include AppDirs Library" ON)
option(BUILD_NETIFACES "Include Netifaces Library" ON)
option(BUILD_PYTHONSIX "Include Python Six Library" ON)
option(BUILD_PYTHON_SETUPTOOLS "Include Python SetupTools Library" ON)
option(BUILD_PYTHON_PACKAGING "Include Python Packaging Library" ON)
option(BUILD_PYPARSING "Include Python Parsing Library" ON)
option(BUILD_PYTHON_NOSE "Include Python NOSE Library" ON)
option(BUILD_MARLIN_FIRMWARES "Build Firmware for 3Dprinters as a part of Cura2 build" OFF)

macro(string_option name info default_value)
    if (${name})
        set(${name} ${${name}} CACHE STRING "${info}")
    else()
        set(${name} ${default_value} CACHE STRING "${info}")
    endif()
endmacro()

string_option(MINIMUM_PYTHON_VERSION "Minimum Python Version" "3.5.0")
string_option(ARCUS_URL "Arcus Git Url" "https://code.alephobjects.com/diffusion/LA/arcus.git")
string_option(SAVITAR_URL "Savitar Git Url" "https://code.alephobjects.com/source/savitar.git")
string_option(CURA_URL "Cura Git Url" "https://code.alephobjects.com/diffusion/CT/Cura2.git")
string_option(CURAENGINE_URL "CuraEngine Git Url" "https://code.alephobjects.com/diffusion/CTE/cura-engine.git")
string_option(URANIUM_URL "Uranium Git Url" "https://code.alephobjects.com/diffusion/U/uranium.git")

if(WIN32)
    option(BUILD_64BIT "Create a 64-bit build" OFF)
endif()

# Create variables to simplify OS management
set(BUILD_OS_OSX OFF)
set(BUILD_OS_LINUX OFF)
set(BUILD_OS_WINDOWS OFF)
set(BUILD_OS_WIN32 OFF)
set(BUILD_OS_WIN64 OFF)

if(CYGWIN)
    message(FATAL_ERROR "Cygwin is not supported")
endif()

if(APPLE)
    set(BUILD_OS_OSX ON)
elseif(WIN32)
    set(BUILD_OS_WINDOWS ON)
    # Possibly all platforms could use SIP 4.19 but Windows is the only one that needs it right now in order to use
    # the pip versions of PyQt5, which only support SIP 4.19.  (Versions of SIP cannot be mixed in the same app.)
    if(BUILD_64BIT)
        set(BUILD_OS_WIN64 ON)
    else()
        set(BUILD_OS_WIN32 ON)
    endif()
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(BUILD_OS_LINUX ON)
else()
    message(FATAL_ERROR "Unsupported Operating System: ${CMAKE_SYSTEM_NAME}")
endif()

# Explicitly disable unsupported options
if(BUILD_OS_WINDOWS)
    if(BUILD_OS_WIN64)
        # Sip is required to build the Arcus python bindings, which works fine on Win32
        # but fails on Win64. So we need an externally built SIP and Arcus bindings on Win64.
        set(BUILD_SIP OFF)
    else()
        set(BUILD_PYTHON OFF)
        set(BUILD_QT OFF)
        set(BUILD_PYQT OFF)
        set(BUILD_OPENBLAS OFF)
        set(BUILD_NUMPY OFF)
        set(BUILD_SCIPY OFF)
        set(BUILD_CYTHON OFF)
        set(PYTHONPATH "${CMAKE_CURRENT_BINARY_DIR}/inst/lib/python3.5/site-packages")
    endif()
elseif(BUILD_OS_LINUX)
	set(BUILD_TYPING OFF)
elseif(BUILD_OS_OSX)
	set(BUILD_TYPING OFF)
endif()

set(TAG_OR_BRANCH "master" CACHE STRING "The name of the tag or branch to build")
set(SAVITAR_TAG_OR_BRANCH ${TAG_OR_BRANCH} CACHE STRING "The name of the Savitar tag or branch to build")
set(CURA_TAG_OR_BRANCH ${TAG_OR_BRANCH} CACHE STRING "The name of the Cura tag or branch to build")
set(URANIUM_TAG_OR_BRANCH ${TAG_OR_BRANCH} CACHE STRING "The name of the Uranium tag or branch to build")
set(CURA_ENGINE_TAG_OR_BRANCH ${TAG_OR_BRANCH} CACHE STRING "The name of the CuraEngine tag or branch to build")

set(EXTRA_REPOSITORIES "" CACHE STRING "Extra repositories to install. Expected to have a CMake based build system.")
set(EXTERNALPROJECT_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/inst)

# Create the version-related variables
# These can optionally be overridden from the build enviroment.
unset(CURA_MAJOR_VERSION CACHE)
if(DEFINED ENV{CURA_MAJOR_VERSION})
    set(CURA_MAJOR_VERSION $ENV{CURA_MAJOR_VERSION} CACHE STRING "Cura Major Version" FORCE)
else()
    set(CURA_MAJOR_VERSION "2" CACHE STRING "Cura Major Version")
endif()
unset(CURA_MINOR_VERSION CACHE)
if(DEFINED ENV{CURA_MINOR_VERSION})
    set(CURA_MINOR_VERSION $ENV{CURA_MINOR_VERSION} CACHE STRING "Cura Minor Version" FORCE)
else()
    set(CURA_MINOR_VERSION "6" CACHE STRING "Cura Minor Version")
endif()
unset(CURA_PATCH_VERSION CACHE)
if(DEFINED ENV{CURA_PATCH_VERSION})
    set(CURA_PATCH_VERSION $ENV{CURA_PATCH_VERSION} CACHE STRING "Cura Patch Version" FORCE)
else()
    set(CURA_PATCH_VERSION "32" CACHE STRING "Cura Patch Version")
endif()
unset(CURA_EXTRA_VERSION CACHE)
if(DEFINED ENV{CURA_EXTRA_VERSION})
    set(CURA_EXTRA_VERSION $ENV{CURA_EXTRA_VERSION} CACHE STRING "Cura Extra Version Information" FORCE)
else()
    set(CURA_EXTRA_VERSION "" CACHE STRING "Cura Extra Version Information")
endif()

set(CURA_VERSION "${CURA_MAJOR_VERSION}.${CURA_MINOR_VERSION}.${CURA_PATCH_VERSION}")
if(NOT "${CURA_EXTRA_VERSION}" STREQUAL "")
    set(CURA_VERSION "${CURA_VERSION}-${CURA_EXTRA_VERSION}")
endif()

if(BUILD_OS_WINDOWS)
    set(MAKE_EXECUTABLE mingw32-make)
    set(CMAKE_C_COMPILER gcc)
    set(CMAKE_CXX_COMPILER g++)
    # Some of the cmake files expect this to be lower-case for some reason ???
    string( TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" CMAKE_SYSTEM_PROCESSOR )
    message(STATUS "---> System Processor: ${CMAKE_SYSTEM_PROCESSOR}")
elseif(BUILD_OS_LINUX OR BUILD_OS_OSX)
    set(MAKE_EXECUTABLE make)
endif()
message(STATUS "---> Make executable: ${MAKE_EXECUTABLE}")

message(STATUS "Building Cura ${CURA_VERSION}")

if(BUILD_PYTHON)
    if(BUILD_OS_OSX)
        set(PYTHON_CONFIGURE_CFLAGS "CFLAGS=-I/usr/local/opt/openssl/include")
        set(PYTHON_CONFIGURE_LDFLAGS "LDFLAGS=-L/usr/local/opt/openssl/lib")
    else()
        set(PYTHON_CONFIGURE_CFLAGS)
        set(PYTHON_CONFIGURE_LDFLAGS)
    endif()
    set(PYTHON_VERSION_MAJOR 3)
    set(PYTHON_VERSION_MINOR 5)
    # For now let's leave only WINDOWS with 3.5.2
    if(BUILD_OS_WINDOWS)
       set(PYTHON_VERSION_PATCH 2)
    else()
       set(PYTHON_VERSION_PATCH 3)
    endif()
    set(PYTHON_VERSION_STRING ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}.${PYTHON_VERSION_PATCH})
    set(PYTHON_EXECUTABLE ${EXTERNALPROJECT_INSTALL_PREFIX}/bin/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR})
    set(Python_ADDITIONAL_VERSIONS ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR})
    set(PYTHONINTERP_FOUND True)

    if(BUILD_OS_WINDOWS)
       set(PYTHON_LIBRARY ${EXTERNALPROJECT_INSTALL_PREFIX}/lib/libpython${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}m.so)
    else()
       set(PYTHON_LIBRARY ${EXTERNALPROJECT_INSTALL_PREFIX}/lib/libpython${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}.so)
    endif()
    set(PYTHON_INCLUDE_DIR ${EXTERNALPROJECT_INSTALL_PREFIX}/include/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR})

    set(EXTRA_PYTHON_DEFINES
           -DBUILD_PYTHON=${BUILD_PYTHON}
           -DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}
           -DPYTHON_VERSION_MAJOR=${PYTHON_VERSION_MAJOR}
           -DPYTHON_VERSION_MINOR=${PYTHON_VERSION_MINOR}
           -DPYTHON_LIBRARY=${PYTHON_LIBRARY}
           -DPYTHON_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}
           -DPython_ADDITIONAL_VERSIONS=${Python_ADDITIONAL_VERSIONS}
    )


    if (BUILD_OS_WINDOWS)
        string(REPLACE "/" "\\" CMAKE_BINARY_DIR "${CMAKE_BINARY_DIR}")
        set (pythonpatch_source_path ${CMAKE_BINARY_DIR}\\PythonPatch-prefix\\src\\PythonPatch\\bin)
        set (pythonpatch_destination_path ${EXTERNALPROJECT_INSTALL_PREFIX}\\bin)

        set(pythonpatch_build_command ${pythonpatch_destination_path}\\patch.exe -t -p1
            -i ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python\\cmake\\patches-win32\\01-PY3-dynload_win.patch
            -d ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python-${PYTHON_VERSION_STRING} )
        list(APPEND pythonpatch_build_command COMMAND ${pythonpatch_destination_path}\\patch.exe -t -p1
            -i ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python\\cmake\\patches-win32\\02-PY3-posixmodule.patch
            -d ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python-${PYTHON_VERSION_STRING} )
        list(APPEND pythonpatch_build_command COMMAND ${pythonpatch_destination_path}\\patch.exe -t -p1
            -i ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python\\cmake\\patches-win32\\03-PY3-getpathp.patch
            -d ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python-${PYTHON_VERSION_STRING} )
        list(APPEND pythonpatch_build_command COMMAND ${pythonpatch_destination_path}\\patch.exe -t -p1
            -i ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python\\cmake\\patches-win32\\04-PY3-pytime.patch
            -d ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python-${PYTHON_VERSION_STRING} )
        list(APPEND pythonpatch_build_command COMMAND ${pythonpatch_destination_path}\\patch.exe -t -p1
            -i ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python\\cmake\\patches-win32\\05-PY3-libffi-latest.patch
            -d ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\Python-${PYTHON_VERSION_STRING} )

        set (pythonpatch_configure_command ${CMAKE_COMMAND} -E copy 
            ${pythonpatch_source_path}\\patch.exe
            ${pythonpatch_destination_path}\\patch.exe )

        ExternalProject_Add(PythonPatch
            URL https://downloads.sourceforge.net/project/gnuwin32/patch/2.5.9-7/patch-2.5.9-7-bin.zip
            CONFIGURE_COMMAND ${pythonpatch_configure_command}
            BUILD_COMMAND ""
            INSTALL_COMMAND ""
            BUILD_IN_SOURCE 1
        )
        list(APPEND pythonpatch_build_command COMMAND)
    else()
        set (pythonpatch_build_command)
        add_custom_target(PythonPatch)
    endif()         

    # For now let's switch WIN to CMAKE Python only
    if(BUILD_OS_WINDOWS) 
      # We'll need to find OpenSSL
      find_package(OpenSSL)
      # For windows we'll try to build using CMake for python
      set(python_configure_command ${pythonpatch_build_command})
      list(APPEND python_configure_command ${CMAKE_COMMAND} <SOURCE_DIR> -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} )
      list(APPEND python_configure_command -DBUILD_LIBPYTHON_SHARED=ON)
      list(APPEND python_configure_command -G ${CMAKE_GENERATOR})
      if (BUILD_OS_WINDOWS)
        list(APPEND python_configure_command -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++)
        # Don't build extensions as built-in
        # list(APPEND python_configure_command -DBUILD_EXTENSIONS_AS_BUILTIN=ON)
        list(APPEND python_configure_command -DENABLE_XXLIMITED=OFF )
        list(APPEND python_configure_command -DENABLE_CTYPES=OFF )
        list(APPEND python_configure_command -DENABLE_CTYPES_TEST=OFF )
      else()
      endif()
      ExternalProject_Add(Python
          DEPENDS PythonPatch
          GIT_REPOSITORY https://code.alephobjects.com/source/python-cmake-buildsystem.git
          GIT_TAG origin/master
          CONFIGURE_COMMAND ${python_configure_command}
          BUILD_COMMAND  ${MAKE_EXECUTABLE}
          INSTALL_COMMAND ${MAKE_EXECUTABLE} install
      )

      # Download python itself and place it into the right spot
            file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/inst/${PYTHON_SITE_PACKAGES_DIR})
            set(_download_link "http://www.python.org/ftp/python/${PYTHON_VERSION_STRING}/Python-${PYTHON_VERSION_STRING}.tgz")
            get_filename_component(_filename ${_download_link} NAME)
            if (BUILD_OS_WINDOWS)
                set(_archive_filepath ${CMAKE_BINARY_DIR}\\Python-prefix\\src\\${_filename})
            else()
                set(_archive_filepath ${CMAKE_BINARY_DIR}/Python-prefix/src/${_filename})
            endif()
            if(EXISTS "${_archive_filepath}")
                message(STATUS "${_archive_filepath} already downloaded")
            else()
                message(STATUS "Downloading ${_archive_filepath}")
                file(
                   DOWNLOAD ${_download_link} ${_archive_filepath}
#                   EXPECTED_MD5 ${_download_${PY_VERSION}_md5}
                   SHOW_PROGRESS
                )
            endif()
            if (BUILD_OS_WINDOWS)
                message(STATUS "Extracting ${_archive_filepath} to  ${CMAKE_BINARY_DIR}\\Python-prefix\\src" )
                execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz ${_archive_filepath}
                    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}\\Python-prefix\\src
                    RESULT_VARIABLE rv)
            else()
                message(STATUS "Extracting ${_archive_filepath} to  ${CMAKE_BINARY_DIR}/Python-prefix/src" )
                execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz ${_archive_filepath}
                    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/Python-prefix/src
                    RESULT_VARIABLE rv)
            endif()
            if(NOT rv EQUAL 0)
                message(FATAL_ERROR "error: extraction of '${_filename}' failed")
            endif()

    else() # elseif(BUILD_OS_OSX OR BUILD_OS_LINUX)
      set( python_configure_command ./configure )
      if (BUILD_OS_OSX)
        list(APPEND python_configure_command --enable-universalsdk)
      endif()
      list(APPEND python_configure_command --prefix=${EXTERNALPROJECT_INSTALL_PREFIX})
      list(APPEND python_configure_command --exec-prefix=${EXTERNALPROJECT_INSTALL_PREFIX})

      list(APPEND python_configure_command --bindir=${EXTERNALPROJECT_INSTALL_PREFIX}/bin)
      list(APPEND python_configure_command --datarootdir=${EXTERNALPROJECT_INSTALL_PREFIX}/share)
      list(APPEND python_configure_command --sbindir=${EXTERNALPROJECT_INSTALL_PREFIX}/bin)
      list(APPEND python_configure_command --libdir=${EXTERNALPROJECT_INSTALL_PREFIX}/lib)
      list(APPEND python_configure_command --libexecdir=${EXTERNALPROJECT_INSTALL_PREFIX}/lib)
      list(APPEND python_configure_command --includedir=${EXTERNALPROJECT_INSTALL_PREFIX}/include)
      list(APPEND python_configure_command --oldincludedir=${EXTERNALPROJECT_INSTALL_PREFIX}/include)
      list(APPEND python_configure_command 
		--enable-shared 
		--with-threads 
		--without-pymalloc 
		${PYTHON_CONFIGURE_CFLAGS} 
		${PYTHON_CONFIGURE_LDFLAGS}
      )
      if (BUILD_OS_OSX)
        set( python_configure_patch_command COMMAND sed -ie 
           "s/#define HAVE_GETENTROPY 1/\\/* #undef HAVE_GETENTROPY *\\//g" pyconfig.h)
        list(APPEND python_configure_patch_command COMMAND 
           echo "fixing pyconfig.h with sed -ie 's/#define HAVE_GETENTROPY 1/\\/* #undef HAVE_GETENTROPY *\\//g'")
        list(APPEND python_configure_patch_command COMMAND sed -ie 
           "s/#define HAVE_CLOCK_GETTIME 1/\\/* #undef HAVE_CLOCK_GETTIME *\\//g" pyconfig.h)
        list(APPEND python_configure_patch_command COMMAND
           echo "fixing pyconfig.h with sed -ie 's/#define HAVE_CLOCK_GETTIME 1/\\/* #undef HAVE_CLOCK_GETTIME *\\//g'")

      else()
        set( python_configure_patch_command)
      endif()
      ExternalProject_Add(Python
          URL https://www.python.org/ftp/python/${PYTHON_VERSION_STRING}/Python-${PYTHON_VERSION_STRING}.tgz
#          PATCH_COMMAND ${python_patch_command}
          CONFIGURE_COMMAND ${python_configure_command} ${python_configure_patch_command}
	
          BUILD_IN_SOURCE 1
      )
   endif()
   # We want to be able to link to python Libs while running CMAKE
   SET( CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} " )
else()
   find_package(PythonInterp ${MINIMUM_PYTHON_VERSION} REQUIRED)
   find_package(PythonLibs REQUIRED)
   add_custom_target(Python) # In order to satisfy dependencies
   set(EXTRA_PYTHON_DEFINES)
endif()
message(STATUS "---> Python executable: ${PYTHON_EXECUTABLE}")
message(STATUS "---> Python libraries: ${PYTHON_LIBRARIES}")
message(STATUS "---> Python includes: ${PYTHON_INCLUDE_DIRS}")
message(STATUS "---> Python libraries version: ${PYTHONLIBS_VERSION_STRING}")

if(BUILD_OS_WINDOWS)
    set(PYTHON_DIRECTORY "python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}")
    set(PYTHON_SITE_PACKAGES_DIR lib/${PYTHON_DIRECTORY}/site-packages)
elseif(BUILD_OS_LINUX OR BUILD_OS_OSX)
    # Set the packages dir to a standard 3.X dir if building Python ourselves
    if (BUILD_PYTHON)
	set(PYTHON_SITE_PACKAGES_DIR lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages)
    else()
	set(PYTHON_SITE_PACKAGES_DIR lib/python${PYTHON_VERSION_MAJOR}/dist-packages)
    endif()
elseif(BUILD_OS_OSX)
    if (BUILD_PYTHON)
	set(PYTHON_SITE_PACKAGES_DIR lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/site-packages)
    else()
	set(PYTHON_SITE_PACKAGES_DIR lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/dist-packages)
    endif()
endif()
message(STATUS "---> Python site-packages: ${PYTHON_SITE_PACKAGES_DIR}")


if(WIN32)
    # To deal with stupid setuptools not creating install directories
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/inst/${PYTHON_SITE_PACKAGES_DIR})
endif()


if(BUILD_QT)
    # set(qt_url http://download.qt.io/archive/qt/5.6/5.6.2/single/qt-everywhere-opensource-src-5.6.2.tar.gz)
    # set(qt_md5 1b1b1f929d0cd83680354a0c83d8e945)
    #set(qt_url http://download.qt.io/archive/qt/5.9/5.9.1/single/qt-everywhere-opensource-src-5.9.1.tar.xz)
    #set(qt_md5 77b4af61c49a09833d4df824c806acaf)
    set(qt_url http://download.lulzbot.com/Software/Cura2/build-resources/qt-everywhere-opensource-src-5.9.1.tar.gz)
    set(qt_md5 e2a13e5a80372e814da08e8b15998a79)

    if(BUILD_OS_WINDOWS)
       set(qt_options configure.bat )
    else()
       set(qt_options ./configure)
    endif()

    list(APPEND qt_options -release)
# If one wants to build debuggable library:
#    list(APPEND qt_options -force-debug-info)
    list(APPEND qt_options -prefix ${EXTERNALPROJECT_INSTALL_PREFIX})
    list(APPEND qt_options -archdatadir ${EXTERNALPROJECT_INSTALL_PREFIX}/lib)
    list(APPEND qt_options -datadir ${EXTERNALPROJECT_INSTALL_PREFIX}/share)
    list(APPEND qt_options -opensource -confirm-license )
    list(APPEND qt_options -nomake examples -nomake tests -nomake tools )
    list(APPEND qt_options -no-cups -no-sql-db2 -no-sql-ibase -no-sql-mysql)
    list(APPEND qt_options -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite -no-sql-sqlite2 -no-sql-tds)

    # It seems like we'll need SSL for Cura2 plugins (Octoprint is using PyQt5.QtNetwork for example)
    if(BUILD_OS_OSX OR BUILD_OS_WINDOWS)
        list(APPEND qt_options -no-openssl )
    endif()
    list(APPEND qt_options -qt-pcre)
    if(BUILD_OS_LINUX OR BUILD_OS_OSX) 
        list(APPEND qt_options -no-eglfs)
    endif()

    list(APPEND qt_options -skip qtconnectivity)
    list(APPEND qt_options -skip qtdoc)
    list(APPEND qt_options -skip qtenginio)
    list(APPEND qt_options -skip qtlocation)
    list(APPEND qt_options -skip qtmultimedia)
    list(APPEND qt_options -skip qtscript)
    list(APPEND qt_options -skip qtsensors)
    list(APPEND qt_options -skip qtwebchannel)
    list(APPEND qt_options -skip qtwebengine)
    list(APPEND qt_options -skip qtwebsockets)
    list(APPEND qt_options -skip qtandroidextras)
    list(APPEND qt_options -skip qtactiveqt)
    list(APPEND qt_options -skip qttools)
    list(APPEND qt_options -skip qtxmlpatterns)
    list(APPEND qt_options -skip qt3d)
    list(APPEND qt_options -skip qtcanvas3d)
    list(APPEND qt_options -skip qtserialport)
    list(APPEND qt_options -skip qtwayland)
    list(APPEND qt_options -skip qtwebview)
    list(APPEND qt_options -skip qtquickcontrols2)
    list(APPEND qt_options -skip qtgraphicaleffects)
    list(APPEND qt_options -skip qtserialbus)
    # Adding these to skip for Qt5.9
    list(APPEND qt_options -skip qtcharts)
    list(APPEND qt_options -skip qtdatavis3d)
    list(APPEND qt_options -skip qtgamepad)
#    list(APPEND qt_options -skip qtnetworkauth)
    list(APPEND qt_options -skip qtpurchasing)
    list(APPEND qt_options -skip qtremoteobjects)
    list(APPEND qt_options -skip qtspeech)
    list(APPEND qt_options -skip qtvirtualkeyboard)
# Following are not disabled:
# qtimageformats coin gnuwin32 qtbase qtdeclarative qtsvg qttranslations qtquickcontrols

    if(BUILD_OS_OSX)
        list(APPEND qt_options -no-framework)
	list(APPEND qt_options -skip qtwinextras -skip qtx11extras)
    elseif(BUILD_OS_WINDOWS)
        list(APPEND qt_options -opengl desktop)
	list(APPEND qt_options -skip qtx11extras -skip qtmacextras)
    elseif(BUILD_OS_LINUX)
        list(APPEND qt_options -no-rpath -qt-xcb)
	list(APPEND qt_options -skip qtmacextras -skip qtwinextras)
    endif()

    if(BUILD_OS_WINDOWS)
       string(REPLACE "/" "\\" qt_options "${qt_options}")
    endif()    
    message(STATUS "---> Qt config: ${qt_options}")
    ExternalProject_Add(Qt
        URL ${qt_url}
        URL_MD5 ${qt_md5}
        CONFIGURE_COMMAND ${qt_options}
        BUILD_IN_SOURCE 1
    )

else()
    message(STATUS "---> System Qt will be used")
    add_custom_target(Qt)
endif()

if(BUILD_SIP)
    set(sip_command ${PYTHON_EXECUTABLE} configure.py )
    list(APPEND sip_command --bindir=${EXTERNALPROJECT_INSTALL_PREFIX}/bin)
    list(APPEND sip_command --destdir=${EXTERNALPROJECT_INSTALL_PREFIX}/${PYTHON_SITE_PACKAGES_DIR} )
    list(APPEND sip_command --incdir=${EXTERNALPROJECT_INSTALL_PREFIX}/include )
    list(APPEND sip_command --sipdir=${EXTERNALPROJECT_INSTALL_PREFIX}/share/sip )
    list(APPEND sip_command --stubsdir=${EXTERNALPROJECT_INSTALL_PREFIX}/${PYTHON_SITE_PACKAGES_DIR} )

    if(BUILD_OS_WINDOWS)
	list(APPEND sip_command --platform win32-g++)
	# Apparently Sip doesn't like hypot
#	list(APPEND sip_command CFLAGS+="-DPy_TRACE_DEFS")
#	list(APPEND sip_command CXXFLAGS+="-DPy_TRACE_DEFS")
    endif()

    if(BUILD_OS_WINDOWS)
        set(SIP_VERSION 0x041301)
        set(SIP_VERSION_STR 4.19.1 )
    else()
        set(SIP_VERSION 0x041301)
        set(SIP_VERSION_STR 4.19.3 )
    endif()
    # set(SIP_VERSION_NUM )
    set(SIP_BINARY_PATH ${EXTERNALPROJECT_INSTALL_PREFIX}/bin/sip )
    set(SIP_DEFAULT_SIP_DIR ${EXTERNALPROJECT_INSTALL_PREFIX}/share/sip )
    set(SIP_INCLUDE_DIR ${EXTERNALPROJECT_INSTALL_PREFIX}/include )
    set(SIP_FOUND True)

    if(BUILD_OS_WINDOWS)
       string(REPLACE "/" "\\" sip_command "${sip_command}")
    endif()
    message(STATUS "---> SIP command: ${sip_command}")
    ExternalProject_Add(Sip
        DEPENDS Python
        URL http://downloads.sourceforge.net/project/pyqt/sip/sip-${SIP_VERSION_STR}/sip-${SIP_VERSION_STR}.zip
        CONFIGURE_COMMAND ${sip_command}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System SIP will be used")
    add_custom_target(Sip)
endif()

#--------------- Building some python modules before PyQt/NumPy/SciPy ------------#
# Platform		Standard installation location			Default value
# Unix (pure)		prefix/lib/pythonX.Y/site-packages		/usr/local/lib/pythonX.Y/site-packages
# Unix (non-pure)	exec-prefix/lib/pythonX.Y/site-packages		/usr/local/lib/pythonX.Y/site-packages
# Windows		prefix\Lib\site-packages			C:\PythonXY\Lib\site-packages

if(BUILD_OS_WINDOWS)
    # Because setuptools is stupid and will interpret "C:/..." as a relative path
    string(REPLACE "/" "\\" native_prefix "${EXTERNALPROJECT_INSTALL_PREFIX}")
    set(python_install
        --install-lib=${native_prefix}\\lib\\${PYTHON_DIRECTORY}\\site-packages
        --install-data=${native_prefix}\\share
        --install-scripts=${native_prefix}\\bin
#	--single-version-externally-managed
	--record=${native_prefix}\\lib\\${PYTHON_DIRECTORY}\\record.txt
    )
elseif(BUILD_OS_LINUX OR BUILD_OS_OSX)
    set(python_install
	--install-lib=${EXTERNALPROJECT_INSTALL_PREFIX}/${PYTHON_SITE_PACKAGES_DIR}
	--install-data=${EXTERNALPROJECT_INSTALL_PREFIX}/share
	--install-scripts=${EXTERNALPROJECT_INSTALL_PREFIX}/bin
#	--single-version-externally-managed 
	--record=${EXTERNALPROJECT_INSTALL_PREFIX}/${PYTHON_SITE_PACKAGES_DIR}/record.txt
    )
endif()
# include_dirs
message(STATUS "---> Python Install: ${python_install}")

# We should not need it, leaving here just in case
# Apparently Six is required for OctoPrint plugin :(
if(BUILD_PYTHONSIX)
    set(build_python_six ${PYTHON_EXECUTABLE} setup.py sdist)
    # --single-version-externally-managed
    set(install_python_six ${PYTHON_EXECUTABLE} setup.py setopt --command=easy_install --option=zip-ok --set-value=False)
    list(APPEND install_python_six COMMAND ${PYTHON_EXECUTABLE} setup.py install --verbose ${python_install} --single-version-externally-managed)
    message(STATUS "---> PythonSix Build: ${build_python_six}")
    message(STATUS "---> PythonSix Install: ${install_python_six}")
    ExternalProject_Add(PythonSix
        DEPENDS Python
        URL https://pypi.python.org/packages/b3/b2/238e2590826bfdd113244a40d9d3eb26918bd798fc187e2360a8367068db/six-1.10.0.tar.gz
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_python_six}
        INSTALL_COMMAND ${install_python_six}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System PythonSix will be used")
    add_custom_target(PythonSix
        DEPENDS Python
    )
endif()

if(BUILD_PYPARSING)
    set(build_pyparsing ${PYTHON_EXECUTABLE} setup.py build)
    # --single-version-externally-managed
    set(install_pyparsing ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose )
    message(STATUS "---> PyParsing Build: ${build_pyparsing}")
    message(STATUS "---> PyParsing Install: ${install_pyparsing}")
    ExternalProject_Add(PyParsing
        DEPENDS Python
        URL https://downloads.sourceforge.net/project/pyparsing/pyparsing/pyparsing-2.2.0/pyparsing-2.2.0.tar.gz
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_pyparsing}
        INSTALL_COMMAND ${install_pyparsing}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System PyParsing will be used")
    add_custom_target(PyParsing
        DEPENDS Python
    )
endif()

if(BUILD_PYTHON_PACKAGING)
    set(build_python_packaging ${PYTHON_EXECUTABLE} setup.py build)
    # --single-version-externally-managed
    set(install_python_packaging ${PYTHON_EXECUTABLE} setup.py setopt --command=easy_install --option=zip-ok --set-value=False)
    list(APPEND install_python_packaging COMMAND ${PYTHON_EXECUTABLE} setup.py install --verbose ${python_install})
    if(BUILD_OS_WINDOWS)
       string(REPLACE "/" "\\" install_python_packaging "${install_python_packaging}")
    endif()
    message(STATUS "---> PythonPackaging Build: ${build_python_packaging}")
    message(STATUS "---> PythonPackaging Install: ${install_python_packaging}")
    ExternalProject_Add(PythonPackaging
        DEPENDS Python PythonSix PyParsing
        GIT_REPOSITORY git://github.com/pypa/packaging.git
        GIT_TAG 79c84ead5177939a9ac93b3532b4a7c15babaffd
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_python_packaging}
        INSTALL_COMMAND ${install_python_packaging}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System PythonPackaging will be used")
    add_custom_target(PythonPackaging
        DEPENDS Python PythonSix PyParsing
    )
endif()

if(BUILD_APPDIRS)
    set(build_python_appdirs ${PYTHON_EXECUTABLE} setup.py build)
    # --single-version-externally-managed
    set(install_python_appdirs ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose)
    message(STATUS "---> PythonAppDirs Build: ${build_python_appdirs}")
    message(STATUS "---> PythonAppDirs Install: ${install_python_appdirs}")
    ExternalProject_Add(PythonAppDirs
        DEPENDS Python
	GIT_REPOSITORY git://github.com/ActiveState/appdirs.git
        GIT_TAG 859eac40ac7d0b5f3260068c4810d027012f0488
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_python_appdirs}
        INSTALL_COMMAND ${install_python_appdirs}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System AppDirs will be used")
    add_custom_target(PythonAppDirs
        DEPENDS Python
    )
endif()

if(BUILD_PYTHON_SETUPTOOLS)
    set(build_python_setuptools ${PYTHON_EXECUTABLE} bootstrap.py COMMAND ${PYTHON_EXECUTABLE} setup.py build)
    set(install_python_setuptools ${PYTHON_EXECUTABLE} setup.py install --verbose ${python_install} --single-version-externally-managed)
    message(STATUS "---> PythonSetupTools Build: ${build_python_setuptools}")
    message(STATUS "---> PythonSetupTools Install: ${install_python_setuptools}")
    ExternalProject_Add(PythonSetupTools
        DEPENDS Python PythonPackaging PythonSix PyParsing PythonAppDirs
        GIT_REPOSITORY git://github.com/pypa/setuptools.git
        GIT_TAG d8e1ed570126dfc99ed7f9126df3bfc890e7005d
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_python_setuptools}
        INSTALL_COMMAND ${install_python_setuptools}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System PythonSetupTools will be used")
    add_custom_target(PythonSetupTools
        DEPENDS Python PythonPackaging PythonSix PyParsing PythonAppDirs
    )
endif()

if(BUILD_PYTHON_UTILS)
    set(build_python_utils ${PYTHON_EXECUTABLE} setup.py build)
    set(install_python_utils ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose --single-version-externally-managed)
    if(BUILD_OS_WINDOWS)
       string(REPLACE "/" "\\" install_python_utils "${install_python_utils}")
    endif()
    message(STATUS "---> PythonUtils Build: ${build_python_utils}")
    message(STATUS "---> PythonUtils Install: ${install_python_utils}")
    ExternalProject_Add(PythonUtils
        DEPENDS Python PythonSetupTools
        GIT_REPOSITORY https://github.com/WoLpH/python-utils.git
        GIT_TAG origin/master
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_python_utils}
        INSTALL_COMMAND ${install_python_utils}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System PythonUtils will be used")
    add_custom_target(PythonUtils
        DEPENDS Python PythonSetupTools
    )
endif()

if(BUILD_NETIFACES)
    set(build_python_netifaces ${PYTHON_EXECUTABLE} setup.py build)
    set(install_python_netifaces ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose --single-version-externally-managed)
    message(STATUS "---> PythonNetifaces Build: ${build_python_netifaces}")
    message(STATUS "---> PythonNetifaces Install: ${install_python_netifaces}")
    ExternalProject_Add(PythonNetifaces
        DEPENDS Python PythonAppDirs PythonUtils
        URL https://pypi.python.org/packages/18/fa/dd13d4910aea339c0bb87d2b3838d8fd923c11869b1f6e741dbd0ff3bc00/netifaces-0.10.4.tar.gz
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_python_netifaces}
        INSTALL_COMMAND ${install_python_netifaces}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System NetIfaces will be used")
    add_custom_target(PythonNetifaces
        DEPENDS Python PythonAppDirs PythonUtils
    )
endif()

if(BUILD_ZEROCONF)
    set(build_python_zeroconf ${PYTHON_EXECUTABLE} setup.py build)
    set(install_python_zeroconf ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose --single-version-externally-managed)
    message(STATUS "---> PythonZeroconf Build: ${build_python_zeroconf}")
    message(STATUS "---> PythonZeroconf Install: ${install_python_zeroconf}")
    ExternalProject_Add(PythonZeroconf
        DEPENDS PythonNetifaces
        GIT_REPOSITORY https://github.com/jstasiak/python-zeroconf
        GIT_TAG 0.17.6
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_python_zeroconf}
        INSTALL_COMMAND ${install_python_zeroconf}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System ZeroConf will be used")
    add_custom_target(PythonZeroconf
        DEPENDS PythonNetifaces
    )
endif()

if ( BUILD_CYTHON )
# Currently Cython can be build only with Python... but we will see
    set(build_cython ${PYTHON_EXECUTABLE} setup.py build)
    if(BUILD_OS_WINDOWS)
         list(APPEND build_cython --compiler=mingw32)
    endif()
    set(install_cython ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose --single-version-externally-managed)
    message(STATUS "---> Cython Build: ${build_cython}")
    message(STATUS "---> Cython Install: ${install_cython}")
    ExternalProject_Add(Cython
        DEPENDS Python Sip PythonAppDirs PythonSetupTools
        URL https://pypi.python.org/packages/b7/67/7e2a817f9e9c773ee3995c1e15204f5d01c8da71882016cac10342ef031b/Cython-0.25.2.tar.gz
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_cython}
        INSTALL_COMMAND ${install_cython}
        BUILD_IN_SOURCE 1
    )
else()
    if(BUILD_OS_WIN32)
        add_custom_target(Cython
            COMMAND ${PYTHON_EXECUTABLE} -m pip install --target=${PYTHONPATH} Cython
            COMMENT "Installing Cython"
        )
    else()
        message(STATUS "---> System Cython will be used")
        add_custom_target(Cython
            DEPENDS Python Sip PythonAppDirs PythonSetupTools
        )
    endif()
endif()

if(BUILD_PYQT)
    set(pyqt_command ${PYTHON_EXECUTABLE} configure.py)
    list(APPEND pyqt_command --confirm-license)
    list(APPEND pyqt_command --destdir=${EXTERNALPROJECT_INSTALL_PREFIX}/${PYTHON_SITE_PACKAGES_DIR})
    list(APPEND pyqt_command --bindir=${EXTERNALPROJECT_INSTALL_PREFIX}/bin)
    list(APPEND pyqt_command --sipdir=${EXTERNALPROJECT_INSTALL_PREFIX}/share/sip)
    list(APPEND pyqt_command --stubsdir=${EXTERNALPROJECT_INSTALL_PREFIX}/${PYTHON_SITE_PACKAGES_DIR})
    list(APPEND pyqt_command --verbose)
    list(APPEND pyqt_command --no-python-dbus)
    list(APPEND pyqt_command --no-designer-plugin)
    if(BUILD_OS_WINDOWS)
        list(APPEND pyqt_command --static )
        list(APPEND pyqt_command --target-py-version=3.5 )
        list(APPEND pyqt_command --spec win32-g++)
        list(APPEND pyqt_command --sip ${EXTERNALPROJECT_INSTALL_PREFIX}/bin/sip.exe)
        list(APPEND pyqt_command --qmake=${EXTERNALPROJECT_INSTALL_PREFIX}/bin/qmake.exe)
        list(APPEND pyqt_command QMAKE_CFLAGS+="-m32 -fPIC -D_hypot=hypot -std=c++11 -static-libstdc++")
        list(APPEND pyqt_command QMAKE_CXXFLAGS+="-m32 -fPIC -D_hypot=hypot -std=c++11 -static-libstdc++")
        list(APPEND pyqt_command QMAKE_LFLAGS+="-LC:/Python35 -LC:/Python35/libs -lpython35")
    elseif(BUILD_OS_LINUX OR BUILD_OS_OSX)
	list(APPEND pyqt_command --sip=${EXTERNALPROJECT_INSTALL_PREFIX}/bin/sip)
	list(APPEND pyqt_command --qmake=${EXTERNALPROJECT_INSTALL_PREFIX}/bin/qmake)
    endif()

    if(BUILD_OS_WINDOWS)
       string(REPLACE "/" "\\" pyqt_command "${pyqt_command}")
    endif()
    message(STATUS "---> PyQt config: ${pyqt_command}")
    ExternalProject_Add(PyQt
        DEPENDS Python Qt Sip
#        URL https://sourceforge.net/projects/pyqt/files/PyQt5/PyQt-5.8.1/PyQt5_gpl-5.8.1.tar.gz/download
	URL https://sourceforge.net/projects/pyqt/files/PyQt5/PyQt-5.9/PyQt5_gpl-5.9.tar.gz/download
#        PATCH_COMMAND ${pyqt_patch}
        CONFIGURE_COMMAND ${pyqt_command}
        BUILD_IN_SOURCE 1
    )
else()
    if(BUILD_OS_WIN32)
        add_custom_target(PyQt
            DEPENDS Python Qt Sip
            COMMAND ${PYTHON_EXECUTABLE} -m pip install --target=${PYTHONPATH} PyQt5==5.7.1
            COMMENT "Installing PyQt5"
        )
    else()
        message(STATUS "---> System PyQt will be used")
        add_custom_target(PyQt
            DEPENDS Python Qt Sip
        )
    endif()
endif()


if(BUILD_OPENBLAS)
    # Fortran compiler is needed for OpenBLAS, but it does no check whether it is available.
    enable_language (Fortran)
    set(openblas_options DYNAMIC_ARCH=1 NO_STATIC=1)

    # Let's Use the git untill we have next release
    message(STATUS "---> OpenBLAS config: ${openblas_options}")
    ExternalProject_Add(OpenBLAS
        # URL https://github.com/xianyi/OpenBLAS/archive/v0.2.19.tar.gz
	GIT_REPOSITORY git://github.com/xianyi/OpenBLAS.git
	GIT_TAG 20a413e154948d8b7fc47e7a6d9f13cae98e3856
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${MAKE_EXECUTABLE} ${openblas_options}
        INSTALL_COMMAND ${MAKE_EXECUTABLE} PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} install
        BUILD_IN_SOURCE 1
    )
    # SET(OpenBLAS_LIBRARIES ${CMAKE_BINARY_DIR}/inst/lib/libopenblas*)
else()
    message(STATUS "---> System OpenBLAS will be used")
    add_custom_target(OpenBLAS)
endif()

if(BUILD_PYTHON_NOSE)
    set(build_python_nose ${PYTHON_EXECUTABLE} setup.py build)
    set(install_python_nose ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose --single-version-externally-managed)
    message(STATUS "---> PythonNose Build: ${build_python_nose}")
    message(STATUS "---> PythonNose Install: ${install_python_nose}")
    ExternalProject_Add(PythonNose
        DEPENDS Python PythonSetupTools
        GIT_REPOSITORY git://github.com/nose-devs/nose.git
        GIT_TAG 7c26ad1e6b7d308cafa328ad34736d34028c122a
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_python_nose}
        INSTALL_COMMAND ${install_python_nose}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System PythonNose will be used")
    add_custom_target(PythonNose
        DEPENDS Python PythonSetupTools
    )
endif()

if(BUILD_NUMPY)
    set(envvar_numpy)
    set(build_numpy ${PYTHON_EXECUTABLE} setup.py)
    if(BUILD_OS_LINUX )
        list(APPEND build_numpy config --compiler=unix --fcompiler=gnu95 )
        list(APPEND build_numpy build_clib --compiler=unix --fcompiler=gnu95 )
        list(APPEND build_numpy build_ext --compiler=unix --fcompiler=gnu95 )

        list(APPEND envvar_numpy CC=gcc CXX=g++ F90=gfortran)
    elseif (BUILD_OS_OSX)
        list(APPEND build_numpy config )
        list(APPEND build_numpy build_clib ) 
        list(APPEND build_numpy build_ext )
#       list(APPEND build_numpy build_ext -j 1 --inplace)
    elseif(BUILD_OS_WINDOWS)
        list(APPEND build_numpy --no-user-cfg )
        list(APPEND build_numpy config --compiler=mingw32 )
        list(APPEND build_numpy setopt --command=ALL --option=extra_compile_args --set-value="")
	list(APPEND build_numpy build_ext)
        list(APPEND build_numpy --compiler=mingw32  )
	list(APPEND build_numpy --fcompiler=gnu95 )
        list(APPEND build_numpy --inplace )
    endif()
#    set(install_numpy ${PYTHON_EXECUTABLE} setup.py install --prefix ${EXTERNALPROJECT_INSTALL_PREFIX})
    set(install_numpy ${PYTHON_EXECUTABLE} setup.py install --single-version-externally-managed ${python_install})
    message(STATUS "---> NumPy build: ${build_numpy}")
    message(STATUS "---> NumPy install: ${install_numpy}")
    ExternalProject_Add(Numpy
        DEPENDS Python OpenBLAS Sip Cython PythonSetupTools PythonNose
        # URL http://downloads.sourceforge.net/project/numpy/NumPy/1.11.2/numpy-1.11.2.tar.gz
        # URL_MD5 03bd7927c314c43780271bf1ab795ebc
	GIT_REPOSITORY git://github.com/numpy/numpy.git
        GIT_TAG 32776774fd6d7f0e62e68ff191b8f834a77932a4
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${envvar_numpy} ${build_numpy}
        INSTALL_COMMAND ${envvar_numpy} ${install_numpy}
        BUILD_IN_SOURCE 1
    )
else()
    if(BUILD_OS_WIN32)
        add_custom_target(Numpy
            DEPENDS Python OpenBLAS Sip Cython PythonSetupTools PythonNose
            COMMAND ${PYTHON_EXECUTABLE} -m pip install --target=${PYTHONPATH} http://software.ultimaker.com/cura-binary-dependencies/numpy-1.11.3+mkl-cp35-cp35m-win32.whl
            COMMENT "Installing NumPy"
        )
    else()
        message(STATUS "---> System NumPy will be used")
        add_custom_target(Numpy
            DEPENDS Python OpenBLAS Sip Cython PythonSetupTools PythonNose
        )
    endif()
endif()

if (BUILD_SCIPY AND BUILD_SCIPY_LITE)
    message(FATAL_ERROR "Can't build SciPy and SciPyLite at the same time")
endif()

if(BUILD_SCIPY)
    set(envvar_scipy)
    set(build_scipy ${PYTHON_EXECUTABLE} setup.py build_ext)
    if(BUILD_OS_LINUX)

         list(APPEND envvar_scipy CC=gcc CXX=g++ F90=gfortran)

         list(APPEND build_scipy config --compiler=unix --fcompiler=gnu95)
         list(APPEND build_scipy build_clib --compiler=unix --fcompiler=gnu95)
         list(APPEND build_scipy build_ext --compiler=unix --fcompiler=gnu95)
         # -i -j 1
    elseif(BUILD_OS_OSX)
         list(APPEND build_scipy config )
         list(APPEND build_scipy build_clib )
         list(APPEND build_scipy build_ext )
    elseif(BUILD_OS_WINDOWS)
         list(APPEND build_scipy config )
         list(APPEND build_scipy build_clib )
         list(APPEND build_scipy build_ext)
    endif()
#    set(install_scipy ${PYTHON_EXECUTABLE} setup.py install --prefix=${EXTERNALPROJECT_INSTALL_PREFIX})
    set(install_scipy ${PYTHON_EXECUTABLE} setup.py install ${python_install} --single-version-externally-managed)

    message(STATUS "---> SciPy build: ${build_scipy}")
    message(STATUS "---> SciPy install: ${install_scipy}")
    ExternalProject_Add(Scipy
        DEPENDS Python PythonUtils Numpy PythonSix PythonPackaging
        # URL http://downloads.sourceforge.net/project/scipy/scipy/0.16.1/scipy-0.16.1.tar.gz
	GIT_REPOSITORY git://github.com/scipy/scipy.git
	GIT_TAG 46cbf563f5010b27017324ca66e1daffb6d21c47
        CONFIGURE_COMMAND ""
	BUILD_COMMAND ${envvar_scipy} ${build_scipy}
        INSTALL_COMMAND ${envvar_scipy} ${install_scipy}
	BUILD_IN_SOURCE 1
    )
elseif(NOT BUILD_SCIPY_LITE)
    if(BUILD_OS_WIN32)
        add_custom_target(Scipy
            DEPENDS Python PythonUtils Numpy PythonSix PythonPackaging
            COMMAND ${PYTHON_EXECUTABLE} -m pip install --target=${PYTHONPATH} http://software.ultimaker.com/cura-binary-dependencies/scipy-0.19.0-cp35-cp35m-win32.whl
            COMMENT "Installing SciPy"
        )
    else()
        message(STATUS "---> System SciPy will be used")
        add_custom_target(Scipy
            DEPENDS Python PythonUtils Numpy PythonSix PythonPackaging
        )
    endif()
endif()

if (BUILD_SCIPY_LITE)
    # PyHULL is needed then
    set(build_pyhull ${PYTHON_EXECUTABLE} setup.py build)
    set(install_pyhull ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose --single-version-externally-managed)
    message(STATUS "---> PyHull Build: ${build_pyhull}")
    message(STATUS "---> PyHull Install: ${install_pyhull}")
    ExternalProject_Add(PyHull
        DEPENDS Python
        URL https://github.com/materialsvirtuallab/pyhull/archive/v1.5.0.tar.gz
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_pyhull}
        INSTALL_COMMAND ${install_pyhull}
        BUILD_IN_SOURCE 1
    )

    # And SciPyLite
    set(build_scipy_lite ${PYTHON_EXECUTABLE} setup.py build)
    set(install_scipy_lite ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose --single-version-externally-managed)
    message(STATUS "---> SciPyLite Build: ${build_scipy_lite}")
    message(STATUS "---> SciPyLite Install: ${install_scipy_lite}")
    ExternalProject_Add(Scipy
        DEPENDS Python PythonUtils Numpy PythonSix PyHull
        GIT_REPOSITORY https://code.alephobjects.com/source/CuraSciPyLite.git
        GIT_TAG origin/master
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_scipy_lite}
        INSTALL_COMMAND ${install_scipy_lite}
        BUILD_IN_SOURCE 1
    )
endif()

if(BUILD_PYSERIAL)
    set(build_pyserial ${PYTHON_EXECUTABLE} setup.py build)
    set(install_pyserial ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose --single-version-externally-managed)
    message(STATUS "---> PySerial Build: ${build_pyserial}")
    message(STATUS "---> PySerial Install: ${install_pyserial}")
    ExternalProject_Add(PySerial
        DEPENDS Python
        URL https://github.com/pyserial/pyserial/releases/download/v3.2.1/pyserial-3.2.1.tar.gz
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_pyserial}
        INSTALL_COMMAND ${install_pyserial}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System PySerial will be used")
    add_custom_target(PySerial
        DEPENDS Python
    )
endif()

if(BUILD_NUMPY_STL )
    set(build_numpystl ${PYTHON_EXECUTABLE} setup.py build)
    set(install_numpystl ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose --single-version-externally-managed)
    message(STATUS "---> NumpySTL Build: ${build_numpystl}")
    message(STATUS "---> NumpySTL Install: ${install_numpystl}")
    ExternalProject_Add(NumpySTL
        DEPENDS Python Numpy PythonUtils
        GIT_REPOSITORY https://github.com/WoLpH/numpy-stl.git
	GIT_TAG 64190e4b4e88a95d38849636f5aad4e0da25af08
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${build_numpystl}
        INSTALL_COMMAND ${install_numpystl}
        BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System NumpySTL will be used")
    add_custom_target(NumpySTL
        DEPENDS Python Numpy PythonUtils
    )
endif()

if(BUILD_TYPING)
    set(build_typing ${PYTHON_EXECUTABLE} setup.py build)
    if(BUILD_OS_WINDOWS)
       set(install_typing ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose)
    else()
       set(install_typing ${PYTHON_EXECUTABLE} setup.py install --single-version-externally-managed ${python_install} --verbose)
    endif()
    message(STATUS "---> PythonTyping Build: ${build_typing}")
    message(STATUS "---> PythonTyping Install: ${install_typing}")
    ExternalProject_Add(PythonTyping
	DEPENDS Python
	URL https://pypi.python.org/packages/17/75/3698d7992a828ad6d7be99c0a888b75ed173a9280e53dbae67326029b60e/typing-3.6.1.tar.gz
	CONFIGURE_COMMAND ""
	BUILD_COMMAND ${build_typing}
	INSTALL_COMMAND ${install_typing}
	BUILD_IN_SOURCE 1
    )
else()
    message(STATUS "---> System PythonTyping will be used")
    add_custom_target(PythonTyping
        DEPENDS Python
    )
endif()

if(BUILD_OS_OSX)
    set(protobuf_cxx_flags "-fPIC -std=c++11 -stdlib=libc++")
elseif(BUILD_OS_WINDOWS)
    # All of the code is PIC on Windows, so -fPIC produces just the bug
    set(protobuf_cxx_flags "-std=c++11 -static-libstdc++")
else()
    set(protobuf_cxx_flags "-fPIC -std=c++11 -static-libstdc++")
endif()
ExternalProject_Add(Protobuf
    # URL https://github.com/google/protobuf/archive/v3.0.0.tar.gz
    # URL_MD5 41f2934b451a82115ccc4aa1f9b156f2
    GIT_REPOSITORY https://github.com/google/protobuf.git
    GIT_TAG 6a4ffb2f90ef7bbd3f20f2a1db4948630ad37dc8
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} -DCMAKE_INSTALL_LIBDIR=lib -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_CXX_FLAGS=${protobuf_cxx_flags} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -G ${CMAKE_GENERATOR} ../Protobuf/cmake
)

if(BUILD_SAVITAR)
  if(BUILD_OS_OSX)
    set(savitar_cxx_flags "-fPIC -std=c++11 -stdlib=libc++")
  elseif(BUILD_OS_WINDOWS)
    # All of the code is PIC on Windows, so -fPIC produces just the bug
    set(savitar_cxx_flags "-std=c++11 -static-libstdc++")
  else()
    set(savitar_cxx_flags "-fPIC -std=c++11 -static-libstdc++")
  endif()
  message(STATUS "---> Savitar will be build") 
  ExternalProject_Add(Savitar
	DEPENDS Python Sip Numpy
    	GIT_REPOSITORY ${SAVITAR_URL}
    	GIT_TAG origin/${SAVITAR_TAG_OR_BRANCH}
    	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} -DCMAKE_CXX_FLAGS=${savitar_cxx_flags} -DBUILD_STATIC=ON -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DPYTHON_SITE_PACKAGES_DIR=${PYTHON_SITE_PACKAGES_DIR} 
# ${EXTRA_PYTHON_DEFINES}
  )
else()
    message(STATUS "---> Savitar will not be build")
    add_custom_target(Savitar
        DEPENDS Python Sip Numpy
    )
endif()

if(BUILD_OS_WIN32)
	set(EXTRA_CBD_ARGS -DBUILD_MARLIN_FIRMWARES=OFF)
	list(APPEND EXTRA_CBD_ARGS -DPACK_FIRMWARE=copy)
else()
	set(EXTRA_CBD_ARGS -DBUILD_MARLIN_FIRMWARES=${BUILD_MARLIN_FIRMWARES})
	list(APPEND EXTRA_CBD_ARGS -DPACK_FIRMWARE=copy)
endif()

ExternalProject_Add(Arcus
    DEPENDS Python Protobuf Sip
    GIT_REPOSITORY ${ARCUS_URL}
    GIT_TAG origin/${TAG_OR_BRANCH}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} -DCMAKE_CXX_FLAGS=-static-libstdc++ -DBUILD_EXAMPLES=OFF -DBUILD_STATIC=ON -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DPYTHON_SITE_PACKAGES_DIR=${PYTHON_SITE_PACKAGES_DIR} -DPROTOBUF_PROTOC_EXECUTABLE=${EXTERNALPROJECT_INSTALL_PREFIX}/bin/protoc -DPROTOBUF_LIBRARY=${EXTERNALPROJECT_INSTALL_PREFIX}/lib/libprotobuf.a -DPROTOBUF_LITE_LIBRARY=${EXTERNALPROJECT_INSTALL_PREFIX}/lib/libprotobuf-lite.a -DPROTOBUF_INCLUDE_DIR=${EXTERNALPROJECT_INSTALL_PREFIX}/include
)

ExternalProject_Add(CuraEngine
    DEPENDS Arcus
    GIT_REPOSITORY ${CURAENGINE_URL}
    GIT_TAG origin/${CURA_ENGINE_TAG_OR_BRANCH}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} -DCURA_ENGINE_VERSION=${CURA_VERSION} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DArcus_DIR=${EXTERNALPROJECT_INSTALL_PREFIX}/lib64/cmake/Arcus
)

ExternalProject_Add(Uranium
    DEPENDS PyQt Arcus
    GIT_REPOSITORY ${URANIUM_URL}
    GIT_TAG origin/${URANIUM_TAG_OR_BRANCH}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} -DMINIMUM_PYTHON_VERSION=${PYTHON_VERSION_STRING} 
)

ExternalProject_Add(Cura-PostProcessing
    DEPENDS Python Uranium Savitar
    GIT_REPOSITORY https://code.alephobjects.com/source/Cura2-PostProcessing.git
    GIT_TAG origin/${CURA_TAG_OR_BRANCH}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX}
)

ExternalProject_Add(cura-binary-data
	DEPENDS Python Uranium Savitar
	GIT_REPOSITORY https://code.alephobjects.com/diffusion/CBD/cura-binary-data.git
	GIT_TAG origin/${TAG_OR_BRANCH}
	CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} ${EXTRA_CBD_ARGS}
)

ExternalProject_Add(fdm_materials
    DEPENDS Python Uranium Savitar
    GIT_REPOSITORY https://github.com/ultimaker/fdm_materials
    GIT_TAG origin/${TAG_OR_BRANCH}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX}
)

ExternalProject_Add(Cura
    DEPENDS Uranium CuraEngine Savitar NumpySTL PythonTyping PySerial PythonZeroconf Scipy Numpy PythonNetifaces fdm_materials cura-binary-data Cura-PostProcessing PythonSix
    GIT_REPOSITORY ${CURA_URL}
    GIT_TAG origin/${CURA_TAG_OR_BRANCH}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} -DMINIMUM_PYTHON_VERSION=${PYTHON_VERSION_STRING} -DURANIUM_SCRIPTS_DIR= -DCURA_VERSION=${CURA_VERSION} -DCMAKE_MODULE_PATH=${EXTERNALPROJECT_INSTALL_PREFIX}/share/cmake-${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}/Modules/
)

set(_last_repo Cura) # To make sure ordering for extra repositories is preserved

foreach(repo ${EXTRA_REPOSITORIES})
    separate_arguments(items UNIX_COMMAND "${repo}")
    list(GET items 0 name)
    list(GET items 1 repo)
    list(REMOVE_AT items 0 1)

    set(cmake "")
    foreach(item ${items})
        list(APPEND cmake ${item})
    endforeach()

    ExternalProject_Add(${name}
        DEPENDS ${_last_repo}
        GIT_REPOSITORY ${repo}
        GIT_TAG origin/master
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNALPROJECT_INSTALL_PREFIX} ${cmake}
    )

    set(_last_repo ${name})
endforeach()


#----- Installers Needs to be build outside of the Cura2 -----#
if(BUILD_OS_OSX)
    #It seems that py2app depends on The following:
    # * setuptools or distribute
    #   setuptools and distribute provide enhancements to distutils, as well as the mechanisms for creating and working with Python Eggs.
    #   Distribute is a fork of setuptools that amongst others adds support for python 3. All testing of py2app is done using distribute.
    # * macholib
    #   macholib reads and writes the Mach-O object file format. Used by py2app to build a dependency graph of dyld and framework 
    #         dependencies for your application
    # * modulegraph
    #   modulegraph is a replacement for the Python standard library modulefinder. Stores the module dependency tree in a graph data 
    #         structure and allows for advanced filtering and analysis capabilities, such as GraphViz dot output.
    # * altgraph
    #   altgraph is a fork of Istvan Albert‘s graphlib, and it used internally by both macholib and modulegraph. It contains several 
    #   small feature and performance enhancements over the original graphlib.

    ExternalProject_Add(Py2App
        DEPENDS Python
        # URL https://pypi.python.org/packages/source/p/py2app/py2app-0.9.tar.gz
        URL https://pypi.python.org/packages/d9/ff/48a8aede5e99db5983039fd0e6c54bb4c0806ef696430d2684348e78249f/py2app-0.12.tar.gz
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${PYTHON_EXECUTABLE} setup.py build
        INSTALL_COMMAND ${PYTHON_EXECUTABLE} setup.py install ${python_install} --verbose
        COMMENT "Building py2app"
        BUILD_IN_SOURCE 1
    )
elseif(BUILD_OS_WINDOWS)
    # Currently, py2exe can not be built with MinGW since the code apparently uses
    # a lot of MSVC-isms. So instead, install py2exe in your Python installation and
    # use that.
    # ExternalProject_Add(Py2Exe
        # DEPENDS Python
        # URL https://pypi.python.org/packages/source/p/py2exe/py2exe-0.9.2.0.zip
        # CONFIGURE_COMMAND ""
        # BUILD_COMMAND ${PYTHON_EXECUTABLE} setup.py build
        # INSTALL_COMMAND ${PYTHON_EXECUTABLE} setup.py install ${python_install}
        # BUILD_IN_SOURCE 1
    # )
elseif(BUILD_OS_LINUX)
    set (envvar_cxFreeze)
    if(BUILD_OS_LINUX)
        list(APPEND envvar_cxFreeze CC=gcc CXX=g++ F90=gfortran)
    elseif(BUILD_OS_OSX)
    elseif(BUILD_OS_WINDOWS)
    endif()
    ExternalProject_Add( cxFreeze
	DEPENDS Python PythonAppDirs
	URL https://pypi.python.org/packages/d0/6d/9492644452727094543575de9846af5a2b9c764f760e2d414af7c876618c/cx_Freeze-5.0.1.tar.gz
	CONFIGURE_COMMAND ""
	BUILD_COMMAND ${envvar_cxFreeze} ${PYTHON_EXECUTABLE} setup.py --no-user-cfg build_ext --library-dirs=${EXTERNALPROJECT_INSTALL_PREFIX}/lib
	INSTALL_COMMAND ${envvar_cxFreeze} ${PYTHON_EXECUTABLE} setup.py --no-user-cfg install ${python_install} --verbose
	COMMENT "Building cxFreeze"
	BUILD_IN_SOURCE 1
    )
endif()

if(BUILD_OS_OSX)
    set(CPACK_GENERATOR "DragNDrop")

    configure_file(setup_osx.py.in setup_osx.py @ONLY)

    add_custom_target(build_app ALL)
    add_dependencies(build_app ${_last_repo} Py2App)

    foreach(repo ${EXTRA_REPOSITORIES})
        separate_arguments(items UNIX_COMMAND "${repo}")
        list(GET items 0 name)
        add_dependencies(build_app ${name})
    endforeach()

    add_custom_command(
        TARGET build_app PRE_LINK
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/dist
        COMMENT "Cleaning old dist/ directory"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

    set(run_py2app LD_LIBRARY_PATH=${EXTERNALPROJECT_INSTALL_PREFIX}/lib)
    list(APPEND run_py2app PYTHONPATH=${EXTERNALPROJECT_INSTALL_PREFIX}/${PYTHON_SITE_PACKAGES_DIR})
    list(APPEND run_py2app ${PYTHON_EXECUTABLE} setup_osx.py py2app --excludes="PyQt5.uic")
    
    add_custom_command(
        TARGET build_app POST_BUILD
        COMMAND ${run_py2app}
        COMMENT "Running py2app :${run_py2app}"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

    set(command_generate_version LD_LIBRARY_PATH=${EXTERNALPROJECT_INSTALL_PREFIX}/lib)
    list(APPEND command_generate_version PYTHONPATH=${EXTERNALPROJECT_INSTALL_PREFIX}/${PYTHON_SITE_PACKAGES_DIR})
    list(APPEND command_generate_version ${PYTHON_EXECUTABLE} scripts/cura_version.py)
    list(APPEND command_generate_version ${CURA_MAJOR_VERSION}.${CURA_MINOR_VERSION}.${CURA_PATCH_VERSION})
    list(APPEND command_generate_version "${CMAKE_BINARY_DIR}" "${CMAKE_BINARY_DIR}/dist")
    add_custom_command(
	TARGET build_app POST_BUILD
	COMMAND ${command_generate_version}
	COMMENT "Generating version.json"
	WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    install(DIRECTORY ${CMAKE_BINARY_DIR}/dist/Cura.app DESTINATION "." USE_SOURCE_PERMISSIONS)

elseif(BUILD_OS_WINDOWS)
    set(CPACK_GENERATOR "NSIS")

    find_program(compiler ${CMAKE_CXX_COMPILER})
    get_filename_component(compiler_dir ${compiler} DIRECTORY)
    configure_file(setup_win32.py.in setup_win32.py @ONLY)

    add_custom_target(build_exe ALL)
    add_dependencies(build_exe ${_last_repo})

    foreach(repo ${EXTRA_REPOSITORIES})
        separate_arguments(items UNIX_COMMAND "${repo}")
        list(GET items 0 name)
        add_dependencies(build_exe ${name})
    endforeach()

    set(CPACK_TOPLEVEL_TAG win)
    set(NSIS_SCRIPT_COPY_PATH "${CMAKE_BINARY_DIR}/_CPack_Packages/win/${CPACK_GENERATOR}")

    add_custom_command(
        TARGET build_exe POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/${CPACK_GENERATOR} ${NSIS_SCRIPT_COPY_PATH}
        COMMENT "Copying NSIS scripts"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )
    add_custom_command(
        TARGET build_exe PRE_LINK
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/dist
        COMMENT "Cleaning old dist/ directory"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

    if(BUILD_OS_WIN32)
        add_custom_command(
            TARGET build_exe POST_BUILD
            COMMAND ${PYTHON_EXECUTABLE} -m pip install --target=${PYTHONPATH} cx_Freeze
            COMMENT "Installing cx_Freeze"
        )
    endif()

    add_custom_command(
        TARGET build_exe POST_BUILD
        COMMAND ${PYTHON_EXECUTABLE} setup_win32.py build
        COMMENT "Running cx_Freeze"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
    add_custom_command(
      TARGET build_exe POST_BUILD
      COMMAND ${PYTHON_EXECUTABLE} scripts/cura_version.py ${CURA_MAJOR_VERSION}.${CURA_MINOR_VERSION}.${CURA_PATCH_VERSION} "${CMAKE_BINARY_DIR}" "${CMAKE_BINARY_DIR}/dist"
      COMMENT "Generating version.json"
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    install(DIRECTORY ${CMAKE_BINARY_DIR}/dist/ DESTINATION "." USE_SOURCE_PERMISSIONS COMPONENT "cura")

    if(BUILD_OS_WIN32)
        install(FILES ${EXTERNALPROJECT_INSTALL_PREFIX}/vcredist_x32.exe DESTINATION "." COMPONENT "vcredist")
    else()
        install(FILES ${EXTERNALPROJECT_INSTALL_PREFIX}/vcredist_x64.exe DESTINATION "." COMPONENT "vcredist")
    endif()

    install(DIRECTORY ${EXTERNALPROJECT_INSTALL_PREFIX}/arduino DESTINATION "." COMPONENT "arduino")

    include(CPackComponent)
    cpack_add_component(cura DISPLAY_NAME "Cura Executable and Data Files" REQUIRED)
    cpack_add_component(vcredist DISPLAY_NAME "Install Visual Studio 2015 Redistributable")
    cpack_add_component(arduino DISPLAY_NAME "Install Arduino Drivers")
elseif(BUILD_OS_LINUX)
    set(CPACK_GENERATOR "DEB")

    set(CPACK_INSTALL_CMAKE_PROJECTS "")
    
    #install(FILES "${CMAKE_BINARY_DIR}/dist/cura2" DESTINATION "/usr/bin")
    #install(FILES "${CMAKE_BINARY_DIR}/dist/CuraEngine" DESTINATION "/usr/bin")
    set(CPACK_INSTALLED_DIRECTORIES
       "${CMAKE_BINARY_DIR}/dist;/usr/share/cura2"
#       "${CMAKE_BINARY_DIR}/dist/lib;/opt/cura2/lib"
#       "${CMAKE_BINARY_DIR}/dist/share;/opt/cura2/share"
    )
#---
    configure_file(setup_linux.py.in setup_linux.py @ONLY)

    add_custom_target(build_app ALL)
    add_dependencies(build_app ${_last_repo} cxFreeze)

    foreach(repo ${EXTRA_REPOSITORIES})
        separate_arguments(items UNIX_COMMAND "${repo}")
        list(GET items 0 name)
        add_dependencies(build_app ${name})
    endforeach()

    add_custom_command(
        TARGET build_app POST_BUILD 
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/dist
        COMMENT "---> Cleaning old cx_Freeze directory : ${CMAKE_BINARY_DIR}/dist"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

    set(run_cx_freeze ${PYTHON_EXECUTABLE} setup_linux.py build --build-exe=${CMAKE_BINARY_DIR}/dist/usr/share/cura2)
    add_custom_command(
        TARGET build_app POST_BUILD
        COMMAND ${run_cx_freeze}
        COMMENT "---> Running cx_Freeze :${run_cx_freeze}"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

    set(run_cura_version ${PYTHON_EXECUTABLE} ${CMAKE_SOURCE_DIR}/scripts/cura_version.py 
	${CURA_VERSION} ${CMAKE_BINARY_DIR} ${CMAKE_BINARY_DIR}/dist)
    add_custom_command(
        TARGET build_app POST_BUILD
        COMMAND ${run_cura_version}
        COMMENT "---> Generating Version File :${run_cura_version}"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
    
    
#---
    set(package_dir "_CPack_Packages/Linux/${CPACK_GENERATOR}/Cura2-${CURA_VERSION}-Linux/")
    set(CPACK_INSTALL_COMMANDS
	"${CMAKE_COMMAND} -E remove_directory ${package_dir}"
        "${CMAKE_COMMAND} -E make_directory ${package_dir}/usr/bin"
        "${CMAKE_COMMAND} -E make_directory ${package_dir}/usr/share/applications"
        "${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/cura2 ${package_dir}/usr/bin/"
        "${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/cura2.desktop ${package_dir}/usr/share/applications/"
    )
    # Removing files, that are not needed for runtime
    # From bin dir
    set(CPACK_IGNORE_FILES "")
endif()

message("CPACK_PACKAGE_VERSION_MAJOR ${CURA_MAJOR_VERSION}")
message("CPACK_PACKAGE_VERSION_MINOR ${CURA_MINOR_VERSION}")
message("CPACK_PACKAGE_VERSION_PATCH ${CURA_PATCH_VERSION}")

set(CPACK_PACKAGE_NAME "Cura2")
set(CPACK_PACKAGE_VENDOR "Ultimaker")
set(CPACK_PACKAGE_VERSION_MAJOR ${CURA_MAJOR_VERSION})
set(CPACK_PACKAGE_VERSION_MINOR ${CURA_MINOR_VERSION})
set(CPACK_PACKAGE_VERSION_PATCH ${CURA_PATCH_VERSION})
set(CPACK_PACKAGE_VERSION ${CURA_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Cura2 3D Printing Software Lulzbot Edition")
set(CPACK_PACKAGE_CONTACT "Aleph Objects <info@alephobjects.com>")
if(NOT BUILD_OS_OSX)
    set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_SOURCE_DIR}/LICENSE)
endif()
set(CPACK_PACKAGE_EXECUTABLES Cura2 "Cura2 ${CURA_MAJOR_VERSION}.${CURA_MINOR_VERSION}.${CURA_PATCH_VERSION}")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Cura2 ${CURA_MAJOR_VERSION}.${CURA_MINOR_VERSION}")

set(RPM_REQUIRES
    "python3 >= ${MINIMUM_PYTHON_VERSION}"
    "python3-qt5 >= 5.4.0"
    "python3-numpy >= 1.9.0"
    "qt5-qtquickcontrols >= 5.4.0"
)
string(REPLACE ";" "," RPM_REQUIRES "${RPM_REQUIRES}")
set(CPACK_RPM_PACKAGE_REQUIRES ${RPM_REQUIRES})
set(CPACK_RPM_PACKAGE_RELOCATABLE OFF)

set(DEB_DEPENDS
    "python3 (>= ${MINIMUM_PYTHON_VERSION})"
    "libgfortran3"
)
string(REPLACE ";" "," DEB_DEPENDS "${DEB_DEPENDS}")
set(CPACK_DEBIAN_PACKAGE_DEPENDS ${DEB_DEPENDS})
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE amd64)
# Set the right epoch so Debian knows this is a more recent version
#set(CPACK_DEBIAN_PACKAGE_VERSION "2:${CPACK_PACKAGE_VERSION}")

set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
set(CPACK_NSIS_EXECUTABLES_DIRECTORY ".")
set(CPACK_NSIS_MUI_FINISHPAGE_RUN "Cura2.exe")
set(CPACK_NSIS_MENU_LINKS
#    "https://ultimaker.com/en/support/software" "Cura Online Documentation"
    "https://https://code.alephobjects.com/project/profile/10" "Cura Development Resources"
)
if(BUILD_OS_WIN32)
    set(CPACK_NSIS_PACKAGE_ARCHITECTURE "32")
else()
    set(CPACK_NSIS_PACKAGE_ARCHITECTURE "64")
endif()

include(CPack)
