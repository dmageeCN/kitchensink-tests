#!/bin/bash

NMPATH="/etc/NetworkManager/system-connections"
# export NHFI=$(opainfo | grep -c Active)

if [[ ! ($USER == "root") ]]; then
    echo "MUST BE ROOT"
    exit 1
fi

get_ifaces() {
    if_out=$(ifconfig 2> /dev/null)
    # if [[ $if_out =~ 'opa_ib0' ]]; then
    #     var=$(for k in $(seq $NHFI); do echo 'opa_ib0'; done)
    #     echo "$var"
    #     return 0
    # fi    
    echo "$if_out" |& awk '/d1/ {print $1}' | tr -d :
}

edit_nmcfg() {
    fpath=$1
    cxid=$2
    if_ip=$3
    node_ip=$4
    sed -i "s/<cxid>/$cxid/g" "$fpath"
    sed -i "s/<if_ip>/$if_ip/g" "$fpath"
    sed -i "s/<node_ip>/$node_ip/g" "$fpath"
}

ifaces=$(get_ifaces)

IFACES=($ifaces)
node_ip=$(grep $(hostname) /etc/hosts | cut -f1 -d' ' | awk -F'.' '{print $NF}')

i=2
for f in "${IFACES[@]}"; do
    nmcli_f=$NMPATH/$f.nmconnection
    cp template.nmconnection $nmcli_f
    edit_nmcfg "$nmcli_f" $f $i $node_ip
    i=$(( i+1 ))
done