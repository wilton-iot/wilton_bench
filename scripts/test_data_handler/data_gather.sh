#!/bin/bash
set -e

# help
if [[ "$1" = "--help" ]]
then
  echo "Usage: $0 working_catalog data_file data_column_number name_of_saved_image [-rm]"
  echo ""
  echo "  -rm - clear working_catalog before any actions"
  echo ""
  echo "   working_catalog - catalog where will be stored tmp files. 1 file - 1 line on plot."
  echo "   data_file - file with data for plot"
  echo "   data_column_number - data column number in data_file. starts from 1"
  echo "   name_of_saved_image - the name of the image that gnuplot will save"
  exit 0
fi


# name revieved variables
store_directory=$1
work_file=$2
param_num=$3
output_file=$4
plotpattern="line"

work_dat_path=$store_directory
echo "process file: '$work_file'"

if [[ "$5" = "-rm" ]]; then
  rm -rf $work_dat_path
fi

if [[ "$5" = "--hist" ]]; then
  plotpattern="hist"
fi

if [[ "$6" = "--hist" ]]; then
  plotpattern="hist"
fi


mkdir -p $work_dat_path

counter=0
file_number=1
start=0

cur_file_name="none"

cat $work_file | while read line
do

  word_counter=1
  cur_param=""
  first=""


  for word in $line; do
    if [[ "$word_counter" = "1" ]]; then
      first=$(echo "$word")
    fi
    if [[ "$word_counter" = "$param_num" ]]; then
      cur_param=$(echo "$word")
      break      
    fi
    word_counter=$(( $word_counter + 1 ))
  done

  if [[ "$first" = "End" ]]; then
    start=0
    file_number=$(( $file_number + 1 ))
  fi

  if [[ "$start" = "1" ]]; then
    echo "$counter $cur_param" >> $work_dat_path/$cur_file_name
    counter=$(( $counter + 1 ))
  fi

  if [[ "$first" = "Run" ]]; then
    # need to generate file name
    word_counter=1
    name_part=""
    for i in $line; do
      if [[ $word_counter -ge 4 ]]; then
        name_part=$(echo "$name_part-$i")
      fi
      word_counter=$(( $word_counter + 1 ))
    done
    cur_file_name=$(echo "line$name_part-$file_number" | sed 's/,//g; s/+/-/g')
    # echo "cur file name: $cur_file_name"
    start=1
    counter=0
  fi
done

# find all data files and build gnuplot command
lines=$(ls $work_dat_path | sed 's/\t/\n/g; s/  /\n/g')

echo "set term png size 1600, 900" >> $work_dat_path/plot.pl
echo "set output \"./$output_file\"" >> $work_dat_path/plot.pl

# two variants of work
# histogramm or lines
if [[ "$plotpattern" = "hist" ]]; then
  echo 'set boxwidth 0.9 absolute'                                    >> $work_dat_path/plot.pl
  echo 'set style fill   solid 1.00 border lt -1'                            >> $work_dat_path/plot.pl
  echo 'set key inside right top vertical Right noreverse noenhanced autotitles nobox'          >> $work_dat_path/plot.pl
  echo 'set style histogram clustered gap 1 title  offset character 0, 0, 0'              >> $work_dat_path/plot.pl

  echo 'set style data histograms'                                    >> $work_dat_path/plot.pl
  echo 'set xtics border in scale 0,0 nomirror rotate by -45  offset character 0, 0, 0 autojustify'    >> $work_dat_path/plot.pl
  echo 'set xtics  norangelimit font ",8"'                                >> $work_dat_path/plot.pl
  echo 'set xtics   ()'                                          >> $work_dat_path/plot.pl
  echo 'set title "" '                                          >> $work_dat_path/plot.pl
  echo 'set ytics  norangelimit font ",8"'                                >> $work_dat_path/plot.pl

  echo "Test Server" >> $output_file.dat
  echo "$lines" | while read line
  do
    data=$(cat $work_dat_path/$line | sed 's/0 //; s/ms//')
    echo "$line $data" >> $output_file.dat
  done

  echo "plot \"$output_file.dat\" using 2:xtic(1) ti col" >> $work_dat_path/plot.pl
else
  echo "plot \\" >> $work_dat_path/plot.pl
  echo "$lines" | while read line
  do
    echo "\"./$work_dat_path/$line\" using 1:2 with lines title '$line', \\" >> $work_dat_path/plot.pl
  done  
fi


# start gnuplot
gnuplot $work_dat_path/plot.pl
