#!/bin/bash

cd build
# cmake -DMINIMUM_PYTHON_VERSION=3.4.0 ../
## For trying out model Subdivider
# cmake -DMINIMUM_PYTHON_VERSION=3.4.0 -DCURA_TAG_OR_BRANCH=model_subdivider -DURANIUM_TAG_OR_BRANCH=model_subdivider ../
## For trying out SciPy Lite
# cmake -DMINIMUM_PYTHON_VERSION=3.4.0 -DCURA_TAG_OR_BRANCH=master -DURANIUM_TAG_OR_BRANCH=master -DBUILD_SCIPY=OFF -DBUILD_SCIPY_LITE=ON ../
# For trying 2.7 branch
cmake -DMINIMUM_PYTHON_VERSION=3.4.0 -DCURA_ENGINE_TAG_OR_BRANCH=upstream2.7 -DCURA_TAG_OR_BRANCH=upstream2.7 -DURANIUM_TAG_OR_BRANCH=upstream2.7 ../
echo "You should be able to monitor progress via \"tail -f `pwd`/cura2_build.log\" in another terminal"
CC=gcc CXX=g++ F90=gfortran PYTHONPATH=`pwd`/inst/lib/python3.5/site-packages PATH=`pwd`/inst/bin:${PATH} LD_LIBRARY_PATH=`pwd`/inst/lib make package &> cura2_build.log
cd ../
# tail -f cura2_build.log
