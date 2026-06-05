# Debug run once

COPY THE commands and adjust them to fit your use case.

``` bash
export INTEL_SETVARS=/opt/intel/oneapi/setvars.sh
export I_MPI_OFI_LIBRARY_INTERNAL=0 # MUST BE 0 for OPX, either for TCP
source $INTEL_SETVARS &> /dev/null
export FI_PROVIDER=tcp # or opx
export I_MPI_PIN_INFO=1
export I_MPI_DEBUG=12

## OPTIONAL
export FI_LOG_LEVEL=debug
export I_MPI_PIN_PROCESSOR_LIST="0-3"s

## IF OPX
export FI_OPX_HFI_SELECT=0 # SOME HFI ID

## IF TCP SET ALL THE VARS TO BE SAFE
# TCP iface either eth0 or something like "ibp*d1"
# Use ifconfig or nmcli connection show to see it
TCP_IFACE=ibp17s0d1 
export FI_TCP_IFACE=$TCP_IFACE
export I_MPI_OFI_INTERFACE=$TCP_IFACE
export FI_IFACE=$TCP_IFACE
```

## COMMAND:

``` bash
mpirun -np 4 -ppn 2 -host cots-08,cots-09 IMB-MPI1 Biband -npmin 99999 -msglog 4:8 -time 1000 -iter 1000
```

I've used SendRecv and Uniband instead of Biband, and messed with the -iter flag.