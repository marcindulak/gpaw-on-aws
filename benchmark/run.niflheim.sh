#!/bin/bash

if test -z $PATTERN;
    then
    echo "Error: no directory pattern provided"
    exit
fi

if test -d $PATTERN;
    then
    echo "Error: directory $PATTERN exists"
    exit
fi

mkdir $PATTERN
cd $PATTERN
PATTERN=$PATTERN sh ../prepare.sh
for dir in ${PATTERN}_*_;
do
    NSLOTS=`echo $dir | cut -d'_' -f2 | tr -d 0`
    cd $dir
    qsub -q medium -l nodes=`expr $NSLOTS / 16`:ppn=16:xeon16 ../../niflheim.sh
    cd ..
done
