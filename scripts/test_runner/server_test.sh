#!/bin/bash
# set -e

# Script starts specified server, monitoring utils and load tests(by wrk)

usage="Usage: $0 [-test] -- server_directory server_name args store_directory wrk_directory server_url wrk_parameters_file\n
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

###################################################

gl_err_state=0

function error_exit {
  echo "$(basename $0): ${1:-"Unknown Error"}" 1>&2
  echo "jobs: '$(jobs -p)'"
  gl_err_state=$?
  count=1
  jobs -p | while read tmp_pid
  do
    echo "pid[$count]: $tmp_pid"
    count=$(( $count + 1 ))
    kill $tmp_pid
  done
  exit 1
}

###################################################


echo "========================="

# setup path vars
server_name=$2
store_directory=$4

wrk_script=$5
wrk_test_data_file=$6

#rm -rf $store_directory
mkdir -p $store_directory


# Run the server in the background. Under perf
$1/$server_name $3 &
# save server pid
echo $! > server.pid

# Run VmRSS handler for server in background
rss_file="vmrss_stat.txt"
$(dirname "$0")/RSS_gatherer.sh server.pid $store_directory/$rss_file &

sleep 1

# run perf connection to server -p. Also in background
# Perf keys:
# -a, --all-cpus   -   System-wide collection from all CPUs.
# -g               -   Enables call-graph (stack chain/backtrace) recording.
# -q               -   Quiet mode, Don’t print any message
# -F 99            -   Profile at this frequency.
#
#perf_out_file="perf.data"
#perf record -F 99 -g -a --output=$store_directory/$perf_out_file -p $(cat server.pid) || error_exit "can't connect perf to server" &


sleep 1

if [[ "$(pgrep $server_name)" = "" ]]; then
  error_exit "can't start server 124"
fi

echo "$1"
echo "$2"
echo "$3"
echo "$4"
echo "$5"
echo "$6"

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
    sleep 2
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
vmstat 1 >> $store_directory/$vm_file & #|| error_exit "can't start vmstat" &

# Running the memory diagnostics
mpstat 1 >> $store_directory/$mp_file & #|| error_exit "can't start mpstat" &

# Run the diagnostics of input / output
iostat -h -d 1 >> $store_directory/$io_file & #|| error_exit "can't start iostat" &

# Running the memory diagnostics for free
free -m -s 1 >> $store_directory/$free_file & #|| error_exit "can't start free" &

current_user=$(whoami)
# Running the memory and cpu diagnostics by 'top'
top -b -u $current_user -d 1 >> $store_directory/$top_file & #|| error_exit "can't start top" &

if [[ "$(pgrep vmstat)" = "" ]]; then
  error_exit "can't start vmstat [main script]"
fi
if [[ "$(pgrep mpstat)" = "" ]]; then
  error_exit "can't start mpstat [main script]"
fi
if [[ "$(pgrep iostat)" = "" ]]; then
  error_exit "can't start iostat [main script]"
fi
if [[ "$(pgrep free)" = "" ]]; then
  error_exit "can't start free [main script]"
fi
if [[ "$(pgrep top)" = "" ]]; then
  error_exit "can't start top [main script]"
fi

jobs -l

sleep 5s

echo "========================="
echo "Let's do some LOAD"
# Run the load


cat $wrk_test_data_file | tail -n +2 | while read threads delim connections delim seconds delim  query
do
  echo "Run with params: $threads, $connections, $seconds, $query" >> $store_directory/$wrk_file

  echo "Run with params: $threads, $connections, $seconds, $query" >> $store_directory/$vm_file
  echo "Run with params: $threads, $connections, $seconds, $query" >> $store_directory/$mp_file
  echo "Run with params: $threads, $connections, $seconds, $query" >> $store_directory/$io_file
  echo "Run with params: $threads, $connections, $seconds, $query" >> $store_directory/$free_file
  echo "Run with params: $threads, $connections, $seconds, $query" >> $store_directory/$top_file
  echo "Run with params: $threads, $connections, $seconds, $query" >> $store_directory/$rss_file

  echo "Run with params: threads=$threads, connections=$connections, seconds=$seconds, query=$query"

  if [[ "$query" = "GET" ]]
  then
    ./wrk -t"$threads" -c"$connections" -d"$seconds"s http://127.0.0.1:8080/app/views/hello >> $store_directory/$wrk_file || error_exit "can't start wrk"
  else
    ./wrk -t"$threads" -c"$connections" -d"$seconds"s -s"$wrk_script" --timeout 5s http://127.0.0.1:8080/app/views/json >> $store_directory/$wrk_file || error_exit "can't start wrk"
  fi

  echo "error state: " $?

  if [[ ! "$(pgrep wrk)" = "" ]]; then
    error_exit "can't start wrk [main script]"
  fi

  echo "=========================" >> $store_directory/$wrk_file
  echo "" >> $store_directory/$wrk_file

  echo "End Run" >> $store_directory/$vm_file
  echo "End Run" >> $store_directory/$mp_file
  echo "End Run" >> $store_directory/$io_file
  echo "End Run" >> $store_directory/$free_file
  echo "End Run" >> $store_directory/$top_file
  echo "End Run" >> $store_directory/$rss_file

  sleep 10s # delay for wrk to free memory
done



echo "========================="
echo "error state: " $?
echo "gl error state: " $gl_err_state
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
sed '/Device/d; /sda/d; /^$/d' $store_directory/$io_file >> $store_directory/$io_file.pc

# Handle freestat.txt
sed '/buffers/d; /Swap/d; /^$/d' $store_directory/$free_file >> $store_directory/$free_file.pc

# Handle vmstat.txt
sed '/procs/d; /free/d; /^$/d' $store_directory/$vm_file >> $store_directory/$vm_file.pc

# Handle mpstat.txt
sed '/CPU/d; /^$/d' $store_directory/$mp_file >> $store_directory/$mp_file.pc

# Handle topstat.txt
echo "$server_name"
sed 's/End Run/\nEnd/;' $store_directory/$top_file | sed 's/Run/\nRun/' | sed -n '/wrk/p; /Run/p; /End/p' >> $store_directory/$top_file.pc.wrk
sed 's/End Run/\nEnd/;' $store_directory/$top_file | sed 's/Run/\nRun/' | sed -n "/$server_name/p; /Run/p; /End/p" >> $store_directory/$top_file.pc.server

# Process wrkstat.txt
sed -n 's/Run/Run/p; s/Latency/Latency/p' $store_directory/$wrk_file | sed '/test/d' | sed 's/Run/End\nRun/g' >> $store_directory/$wrk_file.latency
sed -n 's/Run/Run/p; s/Requests\/sec/Requests\/sec/p' $store_directory/$wrk_file | sed '/test/d' | sed 's/Run/End\nRun/g' >> $store_directory/$wrk_file.requests

echo "End" >> $store_directory/$wrk_file.latency
echo "End" >> $store_directory/$wrk_file.requests


## perf handler
#flame_result_name="flame.svg"
#flame_graph_path="$wrk_path/../FlameGraph" #"../../../utils/FlameGraph"

#echo "perf script --input="$store_directory/$perf_out_file" | $flame_graph_path/stackcollapse-perf.pl | $flame_graph_path/flamegraph.pl > $store_directory/$flame_result_name"
#pkill perf
#sleep 2 # wait for perf saves file
#perf script --input="$store_directory/$perf_out_file" | $flame_graph_path/stackcollapse-perf.pl | $flame_graph_path/flamegraph.pl > $store_directory/$flame_result_name

echo "data ready for processing by data_handler.sh"

rm server.pid
