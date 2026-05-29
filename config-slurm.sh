#!/bin/bash

# export IP_GRP=10.228.221
export NCORES=$(lscpu | awk '/^CPU\(s\):/ {print $NF}')
export PPN=$(( NCORES/4 ))
# export HOSTSIP="${IP_GRP}.121,${IP_GRP}.128" 
export HOSTSNM=$(scontrol show hostnames $SLURM_NODELIST | paste -sd',')