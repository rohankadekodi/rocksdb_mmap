#!/bin/bash

pid=$(ps aux | grep db_bench| grep -v grep | awk '{print $2}')

if [ -z $pid ]; then
    echo "ERROR: could not find running db_bench process"
    exit 1
fi

export LD_LIBRARY_PATH=/home/cc/ScaleMem/app_manager/build/

gdb /home/cc/rocksdb $pid
