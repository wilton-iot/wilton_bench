#!/bin/bash
set -e

scr_cat=$(dirname "$0")

# specify directory with data
tests_path="$scr_cat/../../tests_data/"

# get all catalogs
catalogs=$(ls $tests_path)

# for each catalog run handler
for el in $catalogs; do
	echo "$tests_path$el"
	$scr_cat/run_handler.sh "$tests_path$el"
done