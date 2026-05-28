#!/bin/bash

#SBATCH -p icelake
#SBATCH --reservation=icx

THISFILE=${BASH_SOURCE[0]}
: ${THISFILE:=$0}

THISDIR=$(dirname $(realpath ${THISFILE}))

if [[ ! (-f $THISDIR/util) ]]; then
    echo YOU NEED util.sh in the same directory as this script
    echo in order to run this test
    exit 1
fi

source $THISDIR/util

host_prefix=$(hostname | cut -c-2)

source $THISDIR/config-${host_prefix}.sh

get_swguid

setvar "$@"

universal_opts

HOSTS=$HOSTSNM
if [[ $IPADDR -ne 0 ]]; then HOSTS=$HOSTSIP; fi

export HOSTS
setup_nsdperf $HOSTS

if [[ $KITCHENSINK != 1 ]]; then
  PPN=$(( PPN_ALL/NJOBS ))
else
  TESTS="opx,tcp,verbs"
  NJOBS=2 # echo ${#IFACES_ARRAY[@]}
fi

export OUTNAME="${TEST_NAME}-${SIZE}"

set_opx_size

mkdir -p $OUTDIR
echo "OUTDIR: $OUTDIR"

echo "TESTS: ${TESTS}, PPN: ${PPN}, SIZE: ${SIZE}"

FILES=''
if [[ $TESTS =~ 'tcp' ]]; then
  for k in $(seq $NJOBS); do
    start=$(( (k-1)*PPN ))
    imb_tcp $(( k-1 )) $start  &
    FILES+="${OUTDIR}/TCP-${OUTNAME}-${k}.out,"
  done
fi

if [[ $TESTS =~ 'opx' ]]; then
    startproc=8
    imb_opx 0 $startproc &
    FILES+="${OUTDIR}/OPX-${OUTNAME}-${startproc}.out,"
    startproc=12
    imb_opx 1 $startproc &
    FILES+="${OUTDIR}/OPX-${OUTNAME}-${startproc}.out"
fi

if [[ $TESTS =~ 'verbs' ]]; then
  NSD_PREFIX=${ORIG_PATH}/ # ${OUTPUT_TAG}
  run_run-nsdperf ${NSD_PREFIX}servers ${NSD_PREFIX}clients ${OUTDIR}/nsdperf-incast.out &
fi

sleep 15

check_files "$FILES" | tee -a ${SUMMARY_OUT}
