#echo "Bulk load database into L0...."
#bpl=10485760;overlap=10;mcz=2;del=300000000;levels=7;ctrig=10000000; delay=10000000; stop=10000000; wbn=30; mbc=20; mb=1073741824;wbs=268435456; dds=1; sync=0; r=1000000000; t=1; vs=800; bs=65536; cs=1048576; of=500000; si=1000000; ./db_bench --benchmarks=fillrandom --disable_seek_compaction=1 --mmap_read=0 --statistics=1 --histogram=1 --num=$r --threads=$t --value_size=$vs --block_size=$bs --cache_size=$cs --bloom_bits=10 --cache_numshardbits=4 --open_files=$of --verify_checksum=1 --db=/data/mysql/leveldb/test --sync=$sync --disable_wal=1 --compression_type=zlib --stats_interval=$si --compression_ratio=0.5 --disable_data_sync=$dds --write_buffer_size=$wbs --target_file_size_base=$mb --max_write_buffer_number=$wbn --max_background_compactions=$mbc --level0_file_num_compaction_trigger=$ctrig --level0_slowdown_writes_trigger=$delay --level0_stop_writes_trigger=$stop --num_levels=$levels --delete_obsolete_files_period_micros=$del --min_level_to_compress=$mcz --max_grandparent_overlap_factor=$overlap --stats_per_interval=1 --max_bytes_for_level_base=$bpl --memtablerep=vector --use_existing_db=0 --disable_auto_compactions=1 --source_compaction_factor=10000000
#echo "Running manual compaction to do a global sort map-reduce style...."
#bpl=10485760;overlap=10;mcz=2;del=300000000;levels=2;ctrig=10000000; delay=10000000; stop=10000000; wbn=30; mbc=20; mb=1073741824;wbs=268435456; dds=1; sync=0; r=1000000000; t=1; vs=800; bs=65536; cs=1048576; of=500000; si=1000000; ./db_bench --benchmarks=compact --disable_seek_compaction=1 --mmap_read=0 --statistics=1 --histogram=1 --num=$r --threads=$t --value_size=$vs --block_size=$bs --cache_size=$cs --bloom_bits=10 --cache_numshardbits=4 --open_files=$of --verify_checksum=1 --db=/data/mysql/leveldb/test --sync=$sync --disable_wal=1 --compression_type=zlib --stats_interval=$si --compression_ratio=0.5 --disable_data_sync=$dds --write_buffer_size=$wbs --target_file_size_base=$mb --max_write_buffer_number=$wbn --max_background_compactions=$mbc --level0_file_num_compaction_trigger=$ctrig --level0_slowdown_writes_trigger=$delay --level0_stop_writes_trigger=$stop --num_levels=$levels --delete_obsolete_files_period_micros=$del --min_level_to_compress=$mcz --max_grandparent_overlap_factor=$overlap --stats_per_interval=1 --max_bytes_for_level_base=$bpl --memtablerep=vector --use_existing_db=1 --disable_auto_compactions=1 --source_compaction_factor=10000000

echo "Read Random database ...."
wbs=4194304; r=100000000; t=2; vs=128;
reads=10000000;
cs=1048576; of=64;

#rm -rf /mnt/raid0/flsm/rocksdb-new/*
#sync

iotop -a -btoq -d 0.1 > /tmp/rocksdb-iotop-readrandom-10M &

./db_bench --benchmarks=readrandom --num=$r --reads=$reads --threads=$t --value_size=$vs --cache_size=$cs --bloom_bits=10 --open_files=$of --db=/mnt/raid0/flsm/rocksdbtest-1000 --compression_ratio=0.5 --compression_type=none --write_buffer_size=$wbs --use_existing_db=1

killall iotop
