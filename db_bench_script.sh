#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters; Please provide run and fs as the parameter;"
    exit 1
fi

set -x

runId=$1
fs=$2
ycsbWorkloadsDir=/home/rohan/projects/ycsb_workloads/uniform
rocksDbDir=/home/rohan/projects/rocksdb_mmap
daxResultsDir=/home/rohan/projects/fragmentation/dax/ycsb
novaResultsDir=/home/rohan/projects/fragmentation/nova/ycsb
pmfsResultsDir=/home/rohan/projects/fragmentation/pmfs/ycsb
ramResultsDir=/home/rohan/projects/fragmentation/ramdisk/ycsb
scriptsDir=/home/rohan/projects/rocksdb_mmap/scripts
if [ "$fs" = "ram" ]; then
    pmemDir=/mnt/ramdisk
else
    pmemDir=/mnt/pmem_emul
fi
databaseDir=$pmemDir/rocksdbtest-1000

echo Configuration: 20, 24, 64MB
parameters=' --write_buffer_size=67108864 --open_files=1000 --level0_slowdown_writes_trigger=20 --level0_stop_writes_trigger=24 --mmap_read=true --mmap_write=true --allow_concurrent_memtable_write=true --disable_wal=false --num_levels=7 --memtable_use_huge_page=true --target_file_size_base=67108864 --max_bytes_for_level_base=268435456 --max_bytes_for_level_multiplier=10 --value_size=1024' # --disable_auto_compactions=true'
echo parameters: $parameters

ulimit -c unlimited

mkdir -p $daxResultsDir
mkdir -p $novaResultsDir
mkdir -p $pmfsResultsDir
mkdir -p $ramResultsDir

echo Sleeping for 5 seconds ...
sleep 5

load_workload()
{
    workloadName=$1
    setup=$2

    if [ "$setup" = "nova" ]; then
        resultDir=$novaResultsDir/fill$workloadName
    elif [ "$setup" = "dax" ]; then
        resultDir=$daxResultsDir/fill$workloadName
    elif [ "$setup" = "pmfs" ]; then
        resultDir=$pmfsResultsDir/fill$workloadName
    else
        resultDir=$ramResultsDir/fill$workloadName
    fi

    mkdir -p $resultDir

    echo ----------------------- RocksDB db_bench fillseq ---------------------------
    date
    cd $rocksDbDir

    sudo rm -rf $resultDir/*$runId

    cat /proc/vmstat | grep -e "pgfault" -e "pgmajfault" -e "thp" -e "nr_file" 2>&1 | tee $resultDir/pg_faults_before_Run$runId

    #sudo dmesg -c
    sudo truncate -s 0 /var/log/syslog

    date

    ./db_bench --use_existing_db=0 --benchmarks=fillrandom,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=1 --num=5000000 $parameters 2>&1 | tee $resultDir/Run$runId
    #strace -o trace_fillrandom_dax.out -f ./db_bench --use_existing_db=0 --benchmarks=fillrandom,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=1 --num=1000000 $parameters #2>&1 | tee $resultDir/Run$runId

    date

    #sudo dmesg -c > dmesg_write_log.out
    cp /var/log/syslog $resultDir/syslog_after_Run$runId

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
    setup=$2

    if [ "$setup" = "nova" ]; then
        resultDir=$novaResultsDir/reading$workloadName
    elif [ "$setup" = "dax" ]; then
        resultDir=$daxResultsDir/reading$workloadName
    elif [ "$setup" = "pmfs" ]; then
        resultDir=$pmfsResultsDir/reading$workloadName
    else
        resultDir=$ramResultsDir/reading$workloadName
    fi

    mkdir -p $resultDir

    echo ----------------------- RocksDB db_bench readseq ---------------------------
    date
    cd $rocksDbDir

    sudo rm -rf $resultDir/*$runId

    cat /proc/vmstat | grep -e "pgfault" -e "pgmajfault" -e "thp" -e "nr_file" 2>&1 | tee $resultDir/pg_faults_before_Run$runId

    #sudo dmesg -c
    sudo truncate -s 0 /var/log/syslog

    date

    ./db_bench --use_existing_db=1 --benchmarks=readrandom,stats,levelstats,sstables --db=$databaseDir --compression_type=none --threads=1 --num=5000000 $parameters 2>&1 | tee $resultDir/Run$runId

    date

    #sudo dmesg -c > dmesg_read_log.out
    cp /var/log/syslog $resultDir/syslog_after_Run$runId

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

    #sudo rm -rf $pmemDir/*

    load_workload seq $setup
    $scriptsDir/pause_script.sh 10

    #sudo rm -rf $pmemDir/DR*

    run_workload seq $setup
    $scriptsDir/pause_script.sh 10
}

setup_expt $fs
