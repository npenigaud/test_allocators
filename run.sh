#!/bin/bash

./clean.sh

module purge
module load gcc/14.1.0 &> /dev/null
module load python/3.10.12 &> /dev/null
module load intel/oneapi/2024.1 &> /dev/null
module load tbb/2021.12 &> /dev/null

fypp fiat_tbbpool_mod.fypp > fiat_tbbpool_mod.F90

g++ -std=c++17 -I$TBBROOT/include/tbb -c tbbpool.cpp          
gfortran -c ec_parkind.F90
gfortran -c fiat_tbbpool_mod.F90
gfortran -c essai_probe.F90
gfortran -o probe.x ec_parkind.o fiat_tbbpool_mod.o tbbpool.o essai_probe.o \
         -L$TBBROOT/lib -ltbbmalloc -lstdc++

./probe.x

./clean.sh
