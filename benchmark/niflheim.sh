#!/bin/bash

#PBS -l nodes=2:ppn=1

# -- run in the current working (submission) directory --
if test X$PBS_ENVIRONMENT = XPBS_BATCH; then cd $PBS_O_WORKDIR; fi

export PYTHONDONTWRITEBYTECODE=1  # disable creation of pyc files

. /home/opt/modulefiles/modulefiles_el6.sh
module load GPAW/0.10.0.11364-1

export GPAW_PLATFORM="linux-x86_64-`echo $FYS_PLATFORM | sed 's/-el6//'`-2.6"

# GPAW_HOME must be set after loading the GPAW module!
export GPAW_HOME=${HOME}/benchmark/gpaw-0.11
export PATH=${GPAW_HOME}/build/bin.${GPAW_PLATFORM}:${PATH}
export PATH=${GPAW_HOME}/tools:${PATH}
export PYTHONPATH=${GPAW_HOME}:${PYTHONPATH}
export PYTHONPATH=${GPAW_HOME}/build/lib.${GPAW_PLATFORM}:${PYTHONPATH}

export PYTHONPATH=${HOME}/benchmark/ase-3.9.1:${PYTHONPATH}
export PATH=${HOME}/benchmark/ase-3.9.1/tools:${PATH}

mpiexec gpaw-python ../../b256H2O.py --sl_default=4,4,64

