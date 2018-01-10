#!/bin/bash

# Script starts specified server, monitoring utils and load tests(by wrk)

usage="Usage: $0 [-test] -- server_directory server_name args store_directory server_url wrk_parameters_file\n
\n
-test - wait input  after server start try. If any problems - enter q to quit script."

test_mode="OFF"
while [ -n "$1" ]
do
case "$1" in
-test) test_mode="ON" ;; 
-help) echo -e $usage; exit 0 ;;
--) shift
break ;;
*) echo "$1 is not an option";;
esac
shift
done


echo "========================="

server_name=$2
store_directory=$4

rm -rf $store_directory
mkdir -p $store_directory

# Run the server in the background.
$1$server_name $3 & 

echo "$1"
echo "$2"
echo "$3"
echo "$4"
echo "$5"

if [[ "$test_mode" = "ON" ]] 
then
	echo "enter q to exit"
	read doing #read into the variable $doing from the standard input
	if [[ "$doing" = 'q' ]] 
	then
		echo "exit"
		count=1
		jobs -p | while read tmp_pid
		do
		echo "pid[$count]: $tmp_pid"
		count=$(( $count + 1 ))
		kill $tmp_pid
		done
		exit 0
	fi
fi


wrk_file="wrkstat.txt"
vm_file="vmstat.txt"
mp_file="mpstat.txt"
io_file="iostat.txt"
free_file="freestat.txt"
top_file="topstat.txt"


# Running the cpu diagnostics
vmstat -w 1 >> ./$store_directory/$vm_file &

# Running the memory diagnostics
mpstat 1 >> ./$store_directory/$mp_file &

# Run the diagnostics of input / output
iostat -h -y -d 1 >> ./$store_directory/$io_file &

# Running the memory diagnostics for free
free -m -s 1 >> ./$store_directory/$free_file &

current_user=$(whoami)
# Running the memory and cpu diagnostics by 'top'
top -b -u $current_user -d 1 >> ./$store_directory/$top_file &

jobs -l

sleep 5s

echo "========================="
echo "Let's do some LOAD"
# Run the load

wrk_path="../../tools/wrk" # relative pos in bench catalog
server_url=$5
wrk_test_data_file=$6 


cat $wrk_test_data_file | tail -n +2 | while read threads delim connections delim seconds delim  query
do
	echo "Run with params: $threads, $connections, $seconds, $query" >> ./$store_directory/$wrk_file

	echo "Run with params: $threads, $connections, $seconds, $query" >> ./$store_directory/$vm_file
	echo "Run with params: $threads, $connections, $seconds, $query" >> ./$store_directory/$mp_file
	echo "Run with params: $threads, $connections, $seconds, $query" >> ./$store_directory/$io_file
	echo "Run with params: $threads, $connections, $seconds, $query" >> ./$store_directory/$free_file
	echo "Run with params: $threads, $connections, $seconds, $query" >> ./$store_directory/$top_file

	echo "Run with params: threads=$threads, connections=$connections, seconds=$seconds, query=$query"

	if [[ "$query" = "GET" ]]
	then
		$wrk_path/wrk -t"$threads" -c"$connections" -d"$seconds"s $server_url >> ./$store_directory/$wrk_file
	else
		$wrk_path/wrk -t"$threads" -c"$connections" -d"$seconds"s -s"$wrk_path/scripts/post.lua" $server_url >> ./$store_directory/$wrk_file
	fi
	echo "=========================" >> ./$store_directory/$wrk_file
	echo "" >> ./$store_directory/$wrk_file

	echo "End Run" >> ./$store_directory/$vm_file
	echo "End Run" >> ./$store_directory/$mp_file
	echo "End Run" >> ./$store_directory/$io_file
	echo "End Run" >> ./$store_directory/$free_file
	echo "End Run" >> ./$store_directory/$top_file

	sleep 10s # delay for wrk to free memory
done


echo "========================="
count=1
jobs -p | while read tmp_pid
do
echo "pid[$count]: $tmp_pid"
count=$(( $count + 1 ))
kill $tmp_pid
done
echo "========================="

######
#       Data processing
######
# Now start processing the data
# Handle iostat.txt
sed '/Device/d; /sda/d; /^$/d' ./$store_directory/$io_file >> ./$store_directory/$io_file.pc

# Handle freestat.txt
sed '/buffers/d; /Swap/d; /^$/d' ./$store_directory/$free_file >> ./$store_directory/$free_file.pc

# Handle vmstat.txt
sed '/procs/d; /free/d; /^$/d' ./$store_directory/$vm_file >> ./$store_directory/$vm_file.pc

# Handle mpstat.txt
sed '/CPU/d; /^$/d' ./$store_directory/$mp_file >> ./$store_directory/$mp_file.pc

# Handle topstat.txt
echo "$server_name"
sed 's/End Run/\nEnd/;' ./$store_directory/$top_file | sed 's/Run/\nRun/' | sed -n '/wrk/p; /Run/p; /End/p' >> ./$store_directory/$top_file.pc.wrk
sed 's/End Run/\nEnd/;' ./$store_directory/$top_file | sed 's/Run/\nRun/' | sed -n "/$server_name/p; /Run/p; /End/p" >> ./$store_directory/$top_file.pc.server

# Process wrkstat.txt
sed -n 's/Run/Run/p; s/Latency/Latency/p' ./$store_directory/$wrk_file | sed '/test/d' | sed 's/Run/End\nRun/g' >> ./$store_directory/$wrk_file.latency
sed -n 's/Run/Run/p; s/Requests\/sec/Requests\/sec/p' ./$store_directory/$wrk_file | sed '/test/d' | sed 's/Run/End\nRun/g' >> ./$store_directory/$wrk_file.requests

echo "End" >> ./$store_directory/$wrk_file.latency
echo "End" >> ./$store_directory/$wrk_file.requests


echo "data ready for processing by data_handler.sh"