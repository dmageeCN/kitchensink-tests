#!/bin/bash

serverlist=$1
clientlist=$2

for p in 1 2 4 8 16 # number of threads #
do
for buffsize in 1048576 # msg size
do

parallel=$p
threads=$p

binary="./nsdperf"
if [ ! -f $binary ];then
 ./compile.sh
fi

\rm commands 2>/dev/null

echo "buffsize $buffsize" >> commands
echo "threads $threads" >> commands
echo "parallel $parallel" >> commands
echo "ttime 20" >> commands
echo "usecm on" >> commands

for i in `cat $serverlist`
do
 echo server $i >> commands
done
for i in `cat $clientlist`
do
 echo client $i >> commands
done

echo status >> commands

for i in `seq 1`  #run more than once if desired
do
 #adjust here for whichever tests you want
 echo "test write" >> commands
 echo "test read" >> commands
done

echo "quit" >> commands

./control.sh start $serverlist 
./control.sh start $clientlist 

sleep 5

nclients=`cat $clientlist | wc -l`
nservers=`cat $serverlist | wc -l`

outfile=nsdperf-${nclients}clients-${nservers}servers-${buffsize}buffsize-${threads}threads-${parallel}parallel-${device}-`date +%b-%d-%Y-%H-%M`.out

$binary -i commands | tee $outfile

cat $0 >> $outfile

./control.sh stop $clientlist 
./control.sh stop $serverlist

done
done
