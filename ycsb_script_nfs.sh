#!/bin/bash

# if [ "$#" -ne 2 ]; then
#     echo "Illegal number of parameters; Please provide run and fs as the parameter;"
#     exit 1
# fi

set -x

SCALEMEM_DIR=/home/cc/ScaleMem
CONFIG_DIR="${SCALEMEM_DIR}/node_manager/tests/config.source"
echo "Loading config from $CONFIG_DIR"
source $CONFIG_DIR

# runId=$1
# fs=$2
ycsbWorkloadsDir=/home/cc/ycsb_workloads
nfsDir=/mnt/nfs
databaseDir=$nfsDir
service memcached restart
export HRD_REGISTRY_IP=$NODE_1_IP

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
    ./db_bench --use_existing_db=0 --benchmarks=ycsb,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=8 $parameters | tee /home/cc/ScaleMem/record/rocksdb/run_nfs_$(date +"%Y_%m_%d_%H_%M_%S").log
    #strace -fo ./trace.log ./db_bench --use_existing_db=0 --benchmarks=ycsb,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=8 $parameters

    date
}

setup_expt()
{
    # setup=$1

    rm -rf $nfsDir/*
    file_appendix=25M

    workload LoadA,RunA,RunB,RunC,RunF,RunD $ycsbWorkloadsDir/loada_${file_appendix}_1_8,$ycsbWorkloadsDir/loada_${file_appendix}_2_8,$ycsbWorkloadsDir/loada_${file_appendix}_3_8,$ycsbWorkloadsDir/loada_${file_appendix}_4_8,$ycsbWorkloadsDir/loada_${file_appendix}_5_8,$ycsbWorkloadsDir/loada_${file_appendix}_6_8,$ycsbWorkloadsDir/loada_${file_appendix}_7_8,$ycsbWorkloadsDir/loada_${file_appendix}_8_8,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_1_8,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_2_8,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_3_8,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_4_8,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_5_8,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_6_8,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_7_8,$ycsbWorkloadsDir/runa_${file_appendix}_${file_appendix}_8_8,$ycsbWorkloadsDir/runb_${file_appendix}_${file_appendix}_1_8,$ycsbWorkloadsDir/runb_${file_appendix}_${file_appendix}_2_8,$ycsbWorkloadsDir/runb_${file_appendix}_${file_appendix}_3_8,$ycsbWorkloadsDir/runb_${file_appendix}_${file_appendix}_4_8,$ycsbWorkloadsDir/runb_${file_appendix}_${file_appendix}_5_8,$ycsbWorkloadsDir/runb_${file_appendix}_${file_appendix}_6_8,$ycsbWorkloadsDir/runb_${file_appendix}_${file_appendix}_7_8,$ycsbWorkloadsDir/runb_${file_appendix}_${file_appendix}_8_8,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_1_8,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_2_8,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_3_8,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_4_8,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_5_8,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_6_8,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_7_8,$ycsbWorkloadsDir/runc_${file_appendix}_${file_appendix}_8_8,$ycsbWorkloadsDir/runf_${file_appendix}_${file_appendix}_1_8,$ycsbWorkloadsDir/runf_${file_appendix}_${file_appendix}_2_8,$ycsbWorkloadsDir/runf_${file_appendix}_${file_appendix}_3_8,$ycsbWorkloadsDir/runf_${file_appendix}_${file_appendix}_4_8,$ycsbWorkloadsDir/runf_${file_appendix}_${file_appendix}_5_8,$ycsbWorkloadsDir/runf_${file_appendix}_${file_appendix}_6_8,$ycsbWorkloadsDir/runf_${file_appendix}_${file_appendix}_7_8,$ycsbWorkloadsDir/runf_${file_appendix}_${file_appendix}_8_8,$ycsbWorkloadsDir/rund_${file_appendix}_${file_appendix}_1_8,$ycsbWorkloadsDir/rund_${file_appendix}_${file_appendix}_2_8,$ycsbWorkloadsDir/rund_${file_appendix}_${file_appendix}_3_8,$ycsbWorkloadsDir/rund_${file_appendix}_${file_appendix}_4_8,$ycsbWorkloadsDir/rund_${file_appendix}_${file_appendix}_5_8,$ycsbWorkloadsDir/rund_${file_appendix}_${file_appendix}_6_8,$ycsbWorkloadsDir/rund_${file_appendix}_${file_appendix}_7_8,$ycsbWorkloadsDir/rund_${file_appendix}_${file_appendix}_8_8
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
