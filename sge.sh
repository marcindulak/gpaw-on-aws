#!/bin/bash

#
#$ -S /bin/bash
# -- run in the current working (submission) directory --
#$ -cwd
# -- request mpi 2 slots as listed by "qconf -sq `qconf -sql` |  grep pe_list" --
#$ -pe mpi 2
#

. /etc/profile.d/modules.sh
module purge
module load openmpi-x86_64

cat $PE_HOSTFILE | awk '{printf("%s slots=%d\n", $1, $2)}' > $TMP/hostfile
gpawdir=`gpaw-python_openmpi -c "import gpaw; import os; print os.path.dirname(gpaw.__file__)"`
mpiexec --hostfile $TMP/hostfile -np $NSLOTS gpaw-python_openmpi $gpawdir/test/pw/si_stress.py

