#!/bin/bash

export OMP_NUM_THREADS=16
export GOMP_CPU_AFFINITY=0-15

echo "Running PP/Overlap with Open MPI"
module load openmpi/1.8.4_thread
make clean && make
mpirun -np 2 --map-by node:PE=16 ./mixedModeBenchmark input-pp | tee ompi_pp.out
mpirun -np 2 --map-by node:PE=16 ./mixedModeBenchmark input-overlap | tee ompi_overlap.out

mpirun -np 2 --map-by node:PE=16 --mca mtl ^psm --mca btl_openib_if_include mlx4_0 --mca btl_tcp_if_include eth0 ./mixedModeBenchmark input-pp | tee ompi_pp_mlx.out
mpirun -np 2 --map-by node:PE=16 --mca mtl ^psm --mca btl_openib_if_include mlx4_0 --mca btl_tcp_if_include eth0 ./mixedModeBenchmark input-overlap | tee ompi_overlap_mlx.out

echo "Running PP/Overlap with mvapich"
module unload openmpi/1.8.4_thread
module load mvapich-2.2
make clean && make

NODES=`cat $PBS_NODEFILE | uniq | tr '\n' ' '`

mpirun_rsh -np 2 $NODES MV2_ENABLE_AFFINITY=0 ./mixedModeBenchmark input-pp | tee mvapich_pp.out
mpirun_rsh -np 2 $NODES MV2_ENABLE_AFFINITY=0 ./mixedModeBenchmark input-overlap | tee mvapich_overlap.out

module unload mvapich-2.2
module load mvapich-2.2/mlx

mpirun_rsh -np 2 $NODES MV2_ENABLE_AFFINITY=0 MV2_IBA_HCA=mlx4_0 ./mixedModeBenchmark input-pp | tee mvapich_pp_mlx.out
mpirun_rsh -np 2 $NODES MV2_ENABLE_AFFINITY=0 MV2_IBA_HCA=mlx4_0 ./mixedModeBenchmark input-overlap | tee mvapich_overlap_mlx.out

