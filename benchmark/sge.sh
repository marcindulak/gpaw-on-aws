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
mpiexec --hostfile $TMP/hostfile -np $NSLOTS gpaw-python_openmpi ../../b256H2O.py --sl_default=4,4,64

