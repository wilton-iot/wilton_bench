#!/bin/bash

# specify directory with data
tests_path="../../tests_data/"

# get all catalogs
catalogs=$(ls $tests_path)

# for each catalog run handler
for el in $catalogs; do
	echo "$tests_path$el"
	run_handler.sh "$tests_path$el"
done