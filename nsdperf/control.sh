#!/bin/bash

#modify rootdir to point to your directory
rootdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nodes=$2
rdmadevice=$3

rdmadeviceflag=""
if [ "$rdmadevice" != "" ];then
 rdmadeviceflag="-r $rdmadevice"
fi

if [ "${1}" == "start" ]; then
  echo "Starting nsdperf on ${2}"
  pdsh -w - "$pin ${rootdir}/nsdperf -s $rdmadeviceflag < /dev/null > /dev/null 2>&1 &" < $2
elif [ "${1}" == "status" ]; then
  pdsh -w - "${rootdir}/status.sh" < $2
elif [ "${1}" == "stop" ]; then
  echo Stopping server on ${2}
  pdsh -w - "ps -ef | grep 'nsdperf ' | sed '/grep/d' | awk '{ print \$2 }' | xargs kill -9 2>/dev/null " < $2
fi

