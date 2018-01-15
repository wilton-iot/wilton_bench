#!/bin/bash

pid_file_path=$1
store_file=$2

while [[ true ]]; do
  cat /proc/"$(cat $pid_file_path)"/status | grep VmRSS >> "$store_file" || exit 1
  sleep 1
done
