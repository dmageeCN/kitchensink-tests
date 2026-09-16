#!/bin/bash

THISFILE=${BASH_SOURCE[0]}
: ${THISFILE:=$0}

THISDIR=$(dirname $(realpath ${THISFILE}))

set -m

KITCHEN_DIR=$(dirname $THISDIR)
kitchen_script=$KITCHEN_DIR/kitchensink_screen.sh
ARGS='KITCHENSINK=0 OPX_NJOBS=1 END_MIN=5 PPN=16'

outd=$HOME/perftest/small
mkdir -p $outd
$kitchen_script $ARGS SIZE=SMALL SMALL_ITER=5000 OUTDIR=$outd

outd=$HOME/perftest/large
mkdir -p $outd
$kitchen_script $ARGS SIZE=LARGE LARGE_ITER=30 OUTDIR=$outd

$THISDIR/parse_perftest.sh $HOME/perftest
