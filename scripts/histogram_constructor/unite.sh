#!/bin/bash

usage="Usage: $0 specifick_word\n \t use 'latency' or 'requests'"

if [[ "$1" = "" ]]; then
	echo -e $usage
	exit 0
fi

# Нужно найти файлы

rm -f *.dat.pc
dat_files=$(ls *.png.dat)

header_line="test"

tmp_file="tmp.txt"
mutual_file="mutual.txt"
names_file="names.txt"
file_names_file="file_names.txt"

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
	### Генерация команды для gnuplot
	counter=$(( counter+1 ))
	if [[ "$counter" != "2" ]]; then
		plot_line=$( echo "$plot_line, '' u $counter ti col " )
	fi
	########

	name=$(echo $i | sed "s/\.$1\.png\.dat//")
	echo "$name" >> $names_file
	echo "$i" >> $file_names_file
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

python "unite.py" $1 "$plot_line"

gnuplot plot.plt
