#!/bin/bash

#SBATCH -p icelake
#SBATCH --reservation=icx

THISFILE=${BASH_SOURCE[0]}
: ${THISFILE:=$0}

THISDIR=$(dirname $(realpath ${THISFILE}))

cd $THISDIR

if [[ ! (-f $THISDIR/util) ]]; then
    echo YOU NEED util.sh in the same directory as this script
    echo in order to run this test
    exit 1
fi

source $THISDIR/util

get_config

get_swguid

setvar "$@"

universal_opts

cleanup() {
    export I_MPI_OFI_LIBRARY_INTERNAL=0
    source $INTEL_SETVARS &> /dev/null
    export FI_PROVIDER=opx
    echo "Cleaning up background processes..."
    mpirun -np $NNODES -ppn 1 -host ${HOSTS} pkill -9 nsdperf &> /dev/null
    kill 0
}
trap cleanup EXIT

TOTAL_JOBS=$(( TCP_NJOBS+OPX_NJOBS ))
ppn=$(( NCORES/TOTAL_JOBS ))
if [[ ! (-v $PPN) || ($PPN -gt $ppn) ]]; then
    export PPN=$ppn
fi

# TOTAL_PROCS=$(( TOTAL_JOBS*PPN ))
# if [[ $TOTAL_PROCS -gt $NCORES ]]; then
#     echo "ERROR ERROR"
#     echo "  --- You've launched too many processes: $TOTAL_PROCS."
#     echo "You only have $NCORES cores and launching $TOTAL_JOBS with $PPN procs per node exceeds that."
#     exit 1
# fi

HALF_CORES=$(( NCORES/2 ))
start_count=(0 $HALF_CORES)
echo $HALF_CORES

HOSTS=$HOSTSNM
# if [[ $IPADDR -ne 0 ]]; then HOSTS=$HOSTSIP; fi

export HOSTS
setup_nsdperf $HOSTS

if [[ $KITCHENSINK == 1 ]]; then
  TESTS="opx,tcp,verbs"
fi

export OUTNAME="${TEST_NAME}-${SIZE}"

set_opx_size
sleeper=1
if [[ $UNIT_TEST == 'false' ]]; then
  mkdir -p $OUTDIR
  sleeper=3
else  
  export SUMMARY_OUT=/tmp/unit-test-summary
fi

echo "OUTDIR: $OUTDIR"
echo "TESTS: ${TESTS}, PPN: ${PPN}, SIZE: ${SIZE}"  | tee -a ${SUMMARY_OUT}
echo "TCP JOBS: ${TCP_NJOBS}, OPX_JOBS: ${OPX_NJOBS}"  | tee -a ${SUMMARY_OUT}
echo "NSD_HFI: ${NSD_HFI}, HFI_CYCLE: ${HFI_CYCLE}"  | tee -a ${SUMMARY_OUT}

FILES=''
if [[ $TESTS =~ 'tcp' ]]; then
  for k in $(seq $TCP_NJOBS); do
    count_idx=$(( (k-1)%2 ))
    hfi_idx=$(( (k-1)%NHFI ))
    start_pos=${start_count[$count_idx]}
    echo "+++TCP+$k++ imb_tcp $hfi_idx $start_pos"
    imb_tcp $hfi_idx $start_pos &
    FILES+="${OUTDIR}/TCP-${OUTNAME}-${start_pos}.out,"
    start_count[$count_idx]=$(( start_pos+PPN ))
    sleep $sleeper
  done
fi

if [[ $TESTS =~ 'opx' ]]; then
    for k in $(seq $OPX_NJOBS); do
      count_idx=$(( (k-1)%2 ))
      hfi_idx=$(( (k-1)%NHFI ))
      start_pos=${start_count[$count_idx]}
      echo "+++OPX+$k++ imb_opx $hfi_idx $start_pos"
      imb_opx $hfi_idx $start_pos &
      FILES+="${OUTDIR}/OPX-${OUTNAME}-${start_pos}.out,"
      start_count[$count_idx]=$(( start_pos+PPN ))
      sleep $sleeper
    done
fi
      # startproc=12
      # imb_opx 1 $startproc &
      # FILES+="${OUTDIR}/OPX-${OUTNAME}-${startproc}.out"

if [[ $TESTS =~ 'verbs' ]]; then
  NSD_PREFIX=${ORIG_PATH} # ${OUTPUT_TAG}
  run_run-nsdperf ${NSD_PREFIX}/servers ${NSD_PREFIX}/clients ${OUTDIR}/nsdperf-incast.out &
fi

# WAIT 15 seconds before checking the output.

if [[ $UNIT_TEST == 'true' ]]; then
  sleep 5
  exit 0
fi

sleep 15
files_cut="${FILES%,}"

check_files "$files_cut" | tee -a ${SUMMARY_OUT}
