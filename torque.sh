#!/bin/bash

#PBS -l nodes=2:ppn=1

# -- run in the current working (submission) directory --
if test X$PBS_ENVIRONMENT = XPBS_BATCH; then cd $PBS_O_WORKDIR; fi

. /etc/profile.d/modules.sh
module purge
module load openmpi-x86_64

gpawdir=`gpaw-python_openmpi -c "import gpaw; import os; print os.path.dirname(gpaw.__file__)"`
mpiexec --hostfile $PBS_NODEFILE -np `cat $PBS_NODEFILE | wc -l` gpaw-python_openmpi $gpawdir/test/pw/si_stress.py

