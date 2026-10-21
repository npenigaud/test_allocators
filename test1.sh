#!/bin/bash
./clean.sh
module purge &> /dev/null
rm -f fiat_tbbpool_mod.F90 tbbpool.o &> /dev/null	
module load gcc/14.1.0 &> /dev/null
module load intel/oneapi/2024.1 &> /dev/null
module load tbb/2021.12 &> /dev/null
module load compiler-rt/2024.1.0 &> /dev/null
module load oclfpga/2024.1.0 &> /dev/null
module load compiler/latest &> /dev/null

module load python/3.10.12 &> /dev/null

FFLAGS="-g -traceback -heap-arrays -O2"
CFLAGS="-g -traceback -O2"
echo "     "
echo "compiling doublestack version"
fypp fiat_doublestack_mod.fypp > fiat_doublestack_mod.F90
icx $CFLAGS -c alloc_aligned.c
ifx $FFLAGS -c ec_parkind.F90
ifx $FFLAGS -c fiat_doublestack_mod.F90
ifx $FFLAGS -c mpl_doublestack_mod.F90             # sans -DTBBPOOL : MPL_DOUBLESTACK
ifx $FFLAGS -c essai1_doublestack.F90                     
ifx $FFLAGS -o test_doublestack.x alloc_aligned.o ec_parkind.o fiat_doublestack_mod.o  \
          mpl_doublestack_mod.o essai1_doublestack.o 
              

echo "     "
echo "============================="
echo "compiling ttb version"

fypp fiat_tbbpool_mod.fypp > fiat_tbbpool_mod.F90
icpx $CFLAGS -std=c++17 -I$TBBROOT/include -c tbbpool.cpp          
ifx $FFLAGS -c ec_parkind.F90
ifx $FFLAGS -c fiat_tbbpool_mod.F90
ifx $FFLAGS -DTBBPOOL -c mpl_doublestack_mod.F90             # -DTBBPOOL : MPL_DOUBLESTACK devient un FIAT_TBBPOOL
ifx $FFLAGS -c essai1_doublestack.F90                     
ifx $FFLAGS -o test_tbbpool.x ec_parkind.o fiat_tbbpool_mod.o \
         tbbpool.o mpl_doublestack_mod.o essai1_doublestack.o \
         -L$TBBROOT/lib -ltbbmalloc -lstdc++              



echo "     "
echo "============================="
echo "compiling buddy_malloc version"
fypp fiat_heap_mod.fypp > fiat_heap_mod.F90
icx $CFLAGS -c -std=c99 dev_alloc.c
icx $CFLAGS -c fiat_heap.cc
ifx $FFLAGS -c ec_parkind.F90
ifx $FFLAGS -c fiat_heap_mod.F90 
ifx $FFLAGS -c mpl_heap_mod.F90
ifx $FFLAGS -c essai1_buddy.F90
ifx $FFLAGS -o test_buddy.x dev_alloc.o fiat_heap.o ec_parkind.o fiat_heap_mod.o mpl_heap_mod.o essai1_buddy.o




echo "     "
echo "============================="
echo "testing doublestack 512 Mo -1 with various array sizes"
./test_doublestack.x

echo "     "
echo "============================="
echo "testing tbb 512 Mo -1 with various array sizes"
./test_tbbpool.x


echo "     "
echo "============================="
echo "testing buddy_malloc 512 Mo -1 with various array sizes"
./test_buddy.x

./clean.sh
