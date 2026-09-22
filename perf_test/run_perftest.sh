#!/bin/bash

OUTDIR=$HOME/perftest

THISFILE=${BASH_SOURCE[0]}
: ${THISFILE:=$0}

THISDIR=$(dirname $(realpath ${THISFILE}))
KITCHEN_DIR=$(dirname $THISDIR)

VENV_DIR=$KITCHEN_DIR/.install/perfvenv
if [[ ! (-d $VENV_DIR) ]]; then
    mkdir -p $KITCHEN_DIR/.install
    python3 -m venv $VENV_DIR
    source $VENV_DIR/bin/activate
    pip install pandas matplotlib
else
    source $VENV_DIR/bin/activate
fi

set -m

if [[ -d $OUTDIR ]]; then mv $OUTDIR ${OUTDIR}_old; fi

kitchen_script=$KITCHEN_DIR/kitchensink_screen.sh
ARGS='KITCHENSINK=0 OPX_NJOBS=1 END_MIN=5 PPN=16 TIME_LIMIT=500'

outd=$OUTDIR/small
mkdir -p $outd
$kitchen_script $ARGS SIZE=SMALL OUTDIR=$outd "$@"

outd=$OUTDIR/large
mkdir -p $outd
$kitchen_script $ARGS SIZE=LARGE OUTDIR=$outd "$@"

$THISDIR/parse_perftest.sh $OUTDIR

$THISDIR/plot_perftest.py $OUTDIR
