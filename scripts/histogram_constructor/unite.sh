#!/bin/bash
set -e

usage="Usage: $0 specifick_word path_to_tests_catalog [--clean]\n \t use 'latency' or 'requests' for specifick_word \n \t --clean - flag to clean all work data "

if [[ "$1" = "" ]] || [[ "$2" = "" ]]; then
	echo -e $usage
	exit 0
fi

sc_cat=$(dirname "$0")

rm -f $sc_cat/*.dat.pc
dat_files=$(ls $sc_cat/*.png.dat)

header_line="test"

tmp_file="$sc_cat/tmp.txt"
mutual_file="$sc_cat/mutual.txt"
names_file="$sc_cat/names.txt"
file_names_file="$sc_cat/file_names.txt"

rm -f $tmp_file
rm -f $tmp_file.pc
rm -f $mutual_file
rm -f $tmp_file.pc
rm -f $names_file
rm -f $names_file.pc
rm -f $file_names_file
rm -f $file_names_file.pc

plot_line="plot '$mutual_file' using 2:xtic(1) ti col"

counter=1
for i in $dat_files; do
	######## Generate command for gnuplot
	counter=$(( counter+1 ))
	if [[ "$counter" != "2" ]]; then
		plot_line=$( echo "$plot_line, '' u $counter ti col " )
	fi
	########

	name=$(echo $i | sed "s/\.$1\.png\.dat//")
	name=$(echo $name | tr / "\n"|tail -1|head -1)
	echo "$name" >> $names_file
	echo "$name"
	echo "$i" >> $file_names_file
	echo "$i"
	rm -f $i.pc
	sed "s/Server/$name/" $i >> $i.pc
	header_line=$(echo "$header_line  $name")

	cat $i | tail -n +2 | while read first second
	do
		echo $first >> $tmp_file
	done
done

sort -u $tmp_file >> $tmp_file.pc
sort -u $names_file >> $names_file.pc
sort -u $file_names_file >> $file_names_file.pc

echo $plot_line 

python $sc_cat/unite.py $1 "$plot_line" $sc_cat

gnuplot $sc_cat/plot.plt

mv "$sc_cat/$1.png" "$2/"

if [[ "$3" = "--clean" ]]; then
  echo "clean"
  $sc_cat/clean.sh
fi