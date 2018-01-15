#!/bin/bash

# server test run script name
sr=./server_test.sh

# mutual args
repeate_count=2

tests_path_prefix="../../tests_data/"

wrk_file="wrk_test_params.txt"
wrk_url="http://127.0.0.1:8080/index.html"

# wilton/js vars
wilton_path="../../../build/bin/"
wt=wilton_cli
wt_args_2="../../samples/wilton_js/server.js"
wt_url_2="http://127.0.0.1:8080/app/views/hello"
wt_test_dir_2="js_wilton_test_try_"

# wt_args_4="./js_wilton_server_4_threads/index.js"
# wt_url_4="http://127.0.0.1:8080/js_wilton_server_4_threads/views/hello"
# wt_test_dir_4="js_wilton_test_4_try_"

# nodejs vars
node_args="./node_server/server.js"
node_test_dir="node_test_"

# golang vars
go_path="../../samples/golang/"
go_serv="server"
go_test_dir="go_test_"

# wilton/C API
wtcapi_test_dir="wilton_test_"
wtcapi_path="../../samples/wilton_c/"
wtcapi_name="server"

# Run the tests several times
counter=1
while [ $counter -le $repeate_count ]
do
	$sr -- ""           node         $node_args  "$tests_path_prefix$node_test_dir$counter"   $wrk_url  $wrk_file
	$sr -- $go_path     $go_serv     "proxy"     "$tests_path_prefix$go_test_dir$counter"     $wrk_url  $wrk_file
	$sr -- $wilton_path $wt          $wt_args_2  "$tests_path_prefix$wt_test_dir_2$counter"   $wt_url_2 $wrk_file
	$sr -- $wtcapi_path $wtcapi_name "proxy"     "$tests_path_prefix$wtcapi_test_dir$counter" $wrk_url  $wrk_file
	((counter++))
done