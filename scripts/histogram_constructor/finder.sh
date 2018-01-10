# Нужно найти файлы

# data_files=$(find .. -name *$1.png.dat)

usage="Usage: $0 specifick_word\n \t use 'latency' or 'requests'"

if [[ "$1" = "" ]]; then
	echo -e $usage
	exit 0
fi

finded_files="finded_files.txt"
copy_cmds="copy_cmd.txt"

rm -f $finded_files
rm -f $copy_cmds

# relative path to find tests data
find_path="../../tests_data/"

find $find_path -name *$1.png.dat >> $finded_files

python copy_finded.py $finded_files $copy_cmds


cat $copy_cmds | while read cmd
do
	$cmd
done