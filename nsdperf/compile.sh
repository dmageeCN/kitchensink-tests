#!/bin/bash

g++ -O2 -DRDMA -o nsdperf -lpthread -lrt -libverbs -lrdmacm nsdperf.C
