#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters; Please provide run and fs as the parameter;"
    exit 1
fi

set -x

runId=$1
fs=$2
ycsbWorkloadsDir=/home/rohan/projects/ycsb_workloads
rocksDbDir=/home/rohan/projects/rocksdb_mmap
daxResultsDir=/home/rohan/projects/fragmentation/dax/ycsb
novaResultsDir=/home/rohan/projects/fragmentation/nova/ycsb
pmfsResultsDir=/home/rohan/projects/fragmentation/pmfs/ycsb
ramResultsDir=/home/rohan/projects/fragmentation/ramdisk/ycsb
hugeResultsDir=/home/rohan/projects/fragmentation/hugetlbfs/ycsb
scriptsDir=/home/rohan/projects/rocksdb_mmap/scripts
if [ "$fs" = "ram" ]; then
    pmemDir=/mnt/ramdisk
elif [ "$fs" = "huge" ]; then
    pmemDir=/mnt/hugetlbfs
else
    pmemDir=/mnt/pmem_emul
fi
databaseDir=$pmemDir/rocksdbtest-1000

echo Configuration: 20, 24, 64MB
parameters=' --write_buffer_size=67108864 --open_files=1000 --level0_slowdown_writes_trigger=20 --level0_stop_writes_trigger=24 --mmap_read=true --mmap_write=true --allow_concurrent_memtable_write=true --disable_wal=false --num_levels=7 --memtable_use_huge_page=true --target_file_size_base=67108864 --max_bytes_for_level_base=268435456 --max_bytes_for_level_multiplier=10'
echo parameters: $parameters

ulimit -c unlimited

mkdir -p $daxResultsDir
mkdir -p $novaResultsDir
mkdir -p $pmfsResultsDir
mkdir -p $ramResultsDir
mkdir -p $hugeResultsDir

echo Sleeping for 5 seconds ...
sleep 5

load_workload()
{
    workloadName=$1
    tracefile=$2
    setup=$3

    echo workloadName: $workloadName, tracefile: $tracefile, parameters: $parameters, setup: $setup

    if [ "$setup" = "nova" ]; then
        resultDir=$novaResultsDir/Load$workloadName
    elif [ "$setup" = "dax" ]; then
        resultDir=$daxResultsDir/Load$workloadName
    elif [ "$setup" = "pmfs" ]; then
        resultDir=$pmfsResultsDir/Load$workloadName
    elif [ "$setup" = "huge" ]; then
        resultDir=$hugeResultsDir/Load$workloadName
    else
        resultDir=$ramResultsDir/Load$workloadName
    fi

    mkdir -p $resultDir

    echo ----------------------- RocksDB YCSB Load $workloadName ---------------------------
    date
    export trace_file=$tracefile
    echo Trace file is $trace_file
    cd $rocksDbDir

    sudo rm -rf $resultDir/*$runId

    cat /proc/vmstat | grep -e "pgfault" -e "pgmajfault" -e "thp" -e "nr_file" 2>&1 | tee $resultDir/pg_faults_before_Run$runId

    date
    if [ "$setup" = "huge" ]; then
        LD_PRELOAD=/usr/lib/libhugetlbfs.so HUGETLB_MORECORE=yes ./db_bench --use_existing_db=0 --benchmarks=ycsb,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=1 $parameters 2>&1 | tee $resultDir/Run$runId
    else
        ./db_bench --use_existing_db=0 --benchmarks=ycsb,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=1 $parameters 2>&1 | tee $resultDir/Run$runId
    fi
    date

    cat /proc/vmstat | grep -e "pgfault" -e "pgmajfault" -e "thp" -e "nr_file" 2>&1 | tee $resultDir/pg_faults_after_Run$runId

    echo Sleeping for 5 seconds . .
    sleep 5

    ls -lah $databaseDir/* >> $resultDir/FileInfo$runId
    echo "--------------------------------" >> $resultDir/FileInfo$runId
    ls $databaseDir/ | wc -l >> $resultDir/FileInfo$runId
    echo "--------------------------------" >> $resultDir/FileInfo$runId
    du -sh $databaseDir >> $resultDir/FileInfo$runId

    echo -----------------------------------------------------------------------

    echo Sleeping for 5 seconds ...
    sleep 5
}

run_workload()
{
    workloadName=$1
    tracefile=$2
    setup=$3

    echo "workloadName: $workloadName, tracefile: $tracefile, parameters: $parameters, setup: $setup"

    if [ "$setup" = "nova" ]; then
        resultDir=$novaResultsDir/Run$workloadName
    elif [ "$setup" = "dax" ]; then
        resultDir=$daxResultsDir/Run$workloadName
    elif [ "$setup" = "pmfs" ]; then
        resultDir=$pmfsResultsDir/Run$workloadName
    elif [ "$setup" = "huge" ]; then
        resultDir=$hugeResultsDir/Run$workloadName
    else
        resultDir=$ramResultsDir/Run$workloadName
    fi

    mkdir -p $resultDir

    echo ----------------------- RocksDB YCSB Run $workloadName ---------------------------
    date
    export trace_file=$tracefile
    echo Trace file is $trace_file
    cd $rocksDbDir

    sudo rm -rf $resultDir/*$runId

    cat /proc/vmstat | grep -e "pgfault" -e "pgmajfault" -e "thp" -e "nr_file" 2>&1 | tee $resultDir/pg_faults_before_Run$runId

    sudo dmesg -c

    date
    if [ "$setup" = "huge" ]; then
        LD_PRELOAD=/usr/lib/libhugetlbfs.so HUGETLB_MORECORE=yes ./db_bench --use_existing_db=1 --benchmarks=ycsb,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=1 $parameters 2>&1 | tee $resultDir/Run$runId
    else
        ./db_bench --use_existing_db=1 --benchmarks=ycsb,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=1 $parameters 2>&1 | tee $resultDir/Run$runId
    fi
    date

    sudo dmesg -c > $resultDir/dmesg_log_Run$runId

    cat /proc/vmstat | grep -e "pgfault" -e "pgmajfault" -e "thp" -e "nr_file" 2>&1 | tee $resultDir/pg_faults_after_Run$runId

    echo Sleeping for 5 seconds . .
    sleep 5

    ls -lah $databaseDir/* >> $resultDir/FileInfo$runId
    echo "--------------------------------" >> $resultDir/FileInfo$runId
    ls $databaseDir/ | wc -l >> $resultDir/FileInfo$runId
    echo "--------------------------------" >> $resultDir/FileInfo$runId
    du -sh $databaseDir >> $resultDir/FileInfo$runId

    echo -----------------------------------------------------------------------

    echo Sleeping for 5 seconds ...
    sleep 5
}

setup_expt()
{
    setup=$1

    sudo rm -rf $pmemDir/rocksdbtest-1000

    load_workload a $ycsbWorkloadsDir/loada_5M $setup
    $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    run_workload a $ycsbWorkloadsDir/runa_5M_3M $setup
    $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    run_workload b $ycsbWorkloadsDir/runb_5M_3M $setup
    $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    run_workload c $ycsbWorkloadsDir/runc_5M_3M $setup
    $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    run_workload f $ycsbWorkloadsDir/runf_5M_3M $setup
    $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    run_workload d $ycsbWorkloadsDir/rund_5M_3M $setup
    $scriptsDir/pause_script.sh 10

    sudo rm -rf $pmemDir/rocksdbtest-1000

    load_workload e $ycsbWorkloadsDir/loade_5M $setup
    $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    #mkdir ./temp
    #cp -r $pmemDir/* ./temp/
    #sudo rm -rf $pmemDir/*
    #sudo umount /mnt/pmem_emul
    #sudo mkfs.ext4 -b 4096 /dev/pmem0
    #sudo mount -o dax /dev/pmem0 /mnt/pmem_emul
    #sudo chown -R rohan:rohan /mnt/pmem_emul
    #cp -r ./temp/* $pmemDir/

    run_workload e $ycsbWorkloadsDir/rune_5M_1M $setup
    $scriptsDir/pause_script.sh 10
}

setup_expt $fs
