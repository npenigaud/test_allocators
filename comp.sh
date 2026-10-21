#!/bin/bash
# Variante de double_stack_300.sh : même programme essai_doublestack_300.F90, allocateur tbb fixed_pool.
# Non testé : adapter le chargement de TBB (module, TBBROOT) à votre machine.
./clean.sh
rm -f fiat_tbbpool_mod.F90 tbbpool.o
module purge
module load gcc/14.1.0 &> /dev/null
module load python/3.10.12 &> /dev/null
#### module load tbb    # ou : export TBBROOT=/chemin/vers/oneapi/tbb/latest
###: ${TBBROOT:?définir TBBROOT (répertoire contenant include/oneapi/tbb)}
module load intel/oneapi/2024.1 &> /dev/null
module load tbb/2021.12 &> /dev/null

fypp fiat_doublestack_mod.fypp > fiat_doublestack_mod.F90
fypp fiat_tbbpool_mod.fypp > fiat_tbbpool_mod.F90
gfortran -c alloc_aligned.c
g++ -std=c++17 -I$TBBROOT/include/tbb -c tbbpool.cpp          # ajouter -DUSE_CUDA -I$CUDA_HOME/include pour la mémoire épinglée
gfortran -c ec_parkind.F90
gfortran -c fiat_doublestack_mod.F90
gfortran -c fiat_tbbpool_mod.F90
gfortran -DTBBPOOL -c mpl_doublestack_mod.F90             # -DTBBPOOL : MPL_DOUBLESTACK devient un FIAT_TBBPOOL
gfortran -c essai_doublestack_300.F90                     # inchangé
# les fonctions de pool sont, à ma connaissance, dans libtbbmalloc (ajouter -ltbb si des symboles manquent)
gfortran -o test_tbbpool.x alloc_aligned.o ec_parkind.o fiat_doublestack_mod.o fiat_tbbpool_mod.o \
         tbbpool.o mpl_doublestack_mod.o essai_doublestack_300.o \
         -L$TBBROOT/lib -ltbbmalloc -lstdc++              # + -lcudart si -DUSE_CUDA

gfortran -c essai_probe.F90
gfortran -o probe.x ec_parkind.o fiat_tbbpool_mod.o tbbpool.o essai_probe.o \
         -L$TBBROOT/lib -ltbbmalloc -lstdc++
./probe.x
