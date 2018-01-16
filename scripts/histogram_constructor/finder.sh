#!/bin/bash
set -e

usage="Usage: $0 specifick_word path_to_tests_catalog\n \t use 'latency' or 'requests' as specifick_word"

if [[ "$1" = "" ]] || [[ "$2" = "" ]]; then
	echo -e $usage
	exit 0
fi

sc_cat=$(dirname "$0")


finded_files="$sc_cat/finded_files.txt"
copy_cmds="$sc_cat/copy_cmd.txt"

rm -f $finded_files
rm -f $copy_cmds

# relative path to find tests data
# find_path="$sc_cat/../../tests_data/"
find_path=$2

find $find_path -name *$1.png.dat >> $finded_files

python $sc_cat/copy_finded.py $finded_files $copy_cmds $sc_cat

cat $copy_cmds | while read cmd
do
	$cmd
done