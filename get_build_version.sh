#!/usr/bin/env bash
cd build
grep "SET(CPACK_PACKAGE_VERSION " CPackConfig.cmake | cut -d '"' -f 2
