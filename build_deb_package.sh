#!/bin/bash

cd build
cmake -DMINIMUM_PYTHON_VERSION=3.4.0 -DCURA_TAG_OR_BRANCH=devel -DURANIUM_TAG_OR_BRANCH=devel ../
echo "You should be able to monitor progress via \"tail -f `pwd`/cura2_build.log\" in another terminal"
CC=gcc CXX=g++ F90=gfortran PYTHONPATH=`pwd`/inst/lib/python3.5/site-packages PATH=`pwd`/inst/bin:${PATH} LD_LIBRARY_PATH=`pwd`/inst/lib make package &> cura2_build.log
cd ../
# tail -f cura2_build.log
