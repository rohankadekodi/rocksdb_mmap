#!/bin/bash

# if [ "$#" -ne 2 ]; then
#     echo "Illegal number of parameters; Please provide run and fs as the parameter;"
#     exit 1
# fi

set -x

CONFIG_DIR=/home/cc/ScaleMem/node_manager/tests/config.source
echo "Loading config from $CONFIG_DIR"
source $CONFIG_DIR

# runId=$1
# fs=$2
ycsbWorkloadsDir=/home/cc/ycsb_workloads
pmemDir=/mnt/pmem
databaseDir=$pmemDir

echo Configuration: 20, 24, 64MB
parameters=' --write_buffer_size=67108864 --open_files=1000 --level0_slowdown_writes_trigger=20 --level0_stop_writes_trigger=24 --mmap_read=true --mmap_write=true --allow_concurrent_memtable_write=true --disable_wal=false --num_levels=7 --memtable_use_huge_page=true --target_file_size_base=67108864 --max_bytes_for_level_base=268435456 --max_bytes_for_level_multiplier=10'
echo parameters: $parameters

ulimit -c unlimited
ulimit -n 16384

workload()
{
    workloadName=$1
    tracefile=$2

    echo workloadName: $workloadName, tracefile: $tracefile, parameters: $parameters

    echo ----------------------- RocksDB YCSB $workloadName ---------------------------
    date
    export trace_file=$tracefile
    echo Trace file is $trace_file

    cat /proc/vmstat | grep -e "pgfault" -e "pgmajfault" -e "thp" -e "nr_file"

    date
    # export LD_LIBRARY_PATH=/home/cc/ScaleMem/app_manager/build
    LD_PRELOAD=/home/cc/ScaleMem/app_manager/build/libappmanager.so ./db_bench --use_existing_db=0 --benchmarks=ycsb,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=4 $parameters
    #./db_bench --use_existing_db=0 --benchmarks=ycsb,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=4 $parameters

    date
}

setup_expt()
{
    # setup=$1

    sudo rm -rf $pmemDir/rocksdbtest-1000
    file_appendix=80M

    workload LoadA,RunA,RunC $ycsbWorkloadsDir/loada_${file_appendix}_1_4,$ycsbWorkloadsDir/loada_${file_appendix}_2_4,$ycsbWorkloadsDir/loada_${file_appendix}_3_4,$ycsbWorkloadsDir/loada_${file_appendix}_4_4,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_1_4,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_2_4,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_3_4,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_4_4,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_1_4,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_2_4,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_3_4,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_4_4
    sleep 5
    # $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    # run_workload a $ycsbWorkloadsDir/runa_5M_3M $setup
    # $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    # run_workload b $ycsbWorkloadsDir/runb_5M_3M $setup
    # $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    # run_workload c $ycsbWorkloadsDir/runc_5M_3M $setup
    # $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    # run_workload f $ycsbWorkloadsDir/runf_5M_3M $setup
    # $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    # run_workload d $ycsbWorkloadsDir/rund_5M_3M $setup
    # $scriptsDir/pause_script.sh 10

    # sudo rm -rf $pmemDir/rocksdbtest-1000

    # load_workload e $ycsbWorkloadsDir/loade_5M $setup
    # $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    # run_workload e $ycsbWorkloadsDir/rune_5M_1M $setup
    # $scriptsDir/pause_script.sh 10
}

setup_expt 
