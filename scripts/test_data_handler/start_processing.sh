#!/bin/bash
set -e

usage="Usage: $0 path_to_tests_catalog\n"

if [[ "$1" = "" ]]; then
  echo -e $usage
  exit 0
fi

scr_cat=$(dirname "$0")

# specify directory with data
# tests_path="$scr_cat/../../tests_data/"
tests_path=$1

# get all catalogs
catalogs=$(ls $tests_path)

# for each catalog run handler
for el in $catalogs; do
  if [[ -d "$tests_path/$el" ]]; then
    echo "$tests_path/$el"
    $scr_cat/run_handler.sh "$tests_path/$el"
  fi
done