#!/bin/bash

export IP_GRP=10.228.221
export PPN=16
export PPN_ALL=64
export HOSTSIP="${IP_GRP}.121,${IP_GRP}.128" 
export HOSTSNM="cncc-gnr-003,cncc-gnr-004" #SLURM: ($(scontrol show hostnames)) 