#!/bin/bash

cd build
# cmake ../
## For trying out model Subdivider
# cmake -DMINIMUM_PYTHON_VERSION=3.4.0 -DCURA_TAG_OR_BRANCH=model_subdivider -DURANIUM_TAG_OR_BRANCH=model_subdivider ../
## For trying out SciPy Lite
# cmake -DMINIMUM_PYTHON_VERSION=3.4.0 -DCURA_TAG_OR_BRANCH=master -DURANIUM_TAG_OR_BRANCH=master -DBUILD_SCIPY=OFF -DBUILD_SCIPY_LITE=ON ../
## For trying 3.1 branch
cmake -DCURA_ENGINE_TAG_OR_BRANCH=upstream3.1 -DCURA_TAG_OR_BRANCH=upstream3.1 -DURANIUM_TAG_OR_BRANCH=upstream3.1 ../
echo "You should be able to monitor progress via \"tail -f `pwd`/cura-lulzbot_build.log\" in another terminal"
CC=gcc CXX=g++ F90=gfortran PYTHONPATH=`pwd`/inst/lib/python3.5/site-packages PATH=`pwd`/inst/bin:${PATH} LD_LIBRARY_PATH=`pwd`/inst/lib make package &> cura-lulzbot_build.log
cd ../
