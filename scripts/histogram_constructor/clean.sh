#!/bin/bash
set -e

scr_cat=$(dirname "$0")

rm -f $scr_cat/*png.dat*
rm -f $scr_cat/*.txt*
rm -f $scr_cat/*.png
rm -f $scr_cat/*.plt