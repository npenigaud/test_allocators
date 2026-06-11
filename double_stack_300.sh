#!/bin/bash
./clean.sh
module load gcc/14.1.0 &> /dev/null
module load python/3.10.12 &> /dev/null

fypp fiat_doublestack_mod.fypp > fiat_doublestack_mod.F90
gfortran -c parkind1.F90
gfortran -c fiat_doublestack_mod.F90
gfortran -c mpl_doublestack_mod.F90
gfortran -c essai_doublestack_300.F90
gfortran -o test_doublestack.x parkind1.o fiat_doublestack_mod.o mpl_doublestack_mod.o essai_doublestack_300.o
./test_doublestack.x
