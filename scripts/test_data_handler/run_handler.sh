#!/bin/bash
set -e

scr_cat=$(dirname "$0")

store_directory=$1

wrk_file="wrkstat.txt"
vm_file="vmstat.txt"
mp_file="mpstat.txt"
io_file="iostat.txt"
free_file="freestat.txt"
top_file="topstat.txt"

# create work catalog
work_dat_path=$store_directory/work_dat

mkdir -p $work_dat_path

# Specify data columns positions
cpu_load_pos=3
free_mem_pos=4
io_data_pos=5
top_cpu_usage_pos=9
top_mem_usage_pos=6
latency_pos=2
req_freq_pos=2

plots_path="$store_directory/plots"
mkdir -p $plots_path

# process files
$scr_cat/data_gather.sh $work_dat_path $store_directory/$mp_file.pc $cpu_load_pos ./$plots_path/cpu_load.png -rm
$scr_cat/data_gather.sh $work_dat_path $store_directory/$vm_file.pc $free_mem_pos ./$plots_path/vm_mem.png -rm
$scr_cat/data_gather.sh $work_dat_path $store_directory/$io_file.pc $io_data_pos ./$plots_path/io_stat.png -rm
$scr_cat/data_gather.sh $work_dat_path $store_directory/$free_file.pc $free_mem_pos ./$plots_path/free_mem.png -rm

$scr_cat/data_gather.sh $work_dat_path $store_directory/$top_file.pc.server $top_cpu_usage_pos ./$plots_path/$server_name-cpu_usage.png -rm
$scr_cat/data_gather.sh $work_dat_path $store_directory/$top_file.pc.server $top_mem_usage_pos ./$plots_path/$server_name-mem_usage.png -rm

$scr_cat/data_gather.sh $work_dat_path $store_directory/$top_file.pc.wrk $top_cpu_usage_pos ./$plots_path/wrk_cpu_usage.png -rm
$scr_cat/data_gather.sh $work_dat_path $store_directory/$top_file.pc.wrk $top_mem_usage_pos ./$plots_path/wrk_mem_usage.png -rm

$scr_cat/data_gather.sh $work_dat_path $store_directory/$wrk_file.latency $latency_pos ./$plots_path/latency.png -rm --hist
$scr_cat/data_gather.sh $work_dat_path $store_directory/$wrk_file.requests $req_freq_pos ./$plots_path/requests.png -rm --hist
