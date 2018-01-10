

import os

import copy
import sys


finded_files_storage = sys.argv[1]
copy_cmd_file = sys.argv[2]

copy_commands = open(copy_cmd_file, "w")
finded = open(finded_files_storage)
for line in finded.readlines():
	str_val = line.replace('\n','')
	str_list = str_val.split('/') 
	suffix = str_list.pop()
	str_list.pop() # skip plots catalog
	prefix = str_list.pop()
	new_name = prefix + "." + suffix
	copy_command = "cp " + str_val + " ./" + new_name + "\n"
	copy_commands.write(copy_command)



