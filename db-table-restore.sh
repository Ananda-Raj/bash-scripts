#!/bin/bash

# Script to restore specific table from database dump
# Author: Ananda Raj
# Date: 4 Sep 2020
# Version 1.31012020

# Where to restore
db_host='localhost'
db_name='database_name'
db_user='database_username'
db_pass='database_password'

# Dump file location
dump_file='/home/username/backup/database_name.sql'

# Associative table list array as source_table=destination_table pairs.
declare -A tbl_list=( ["table_name1"]="new_table_name1" ["table_name2"]="new_table_name2")

for tbl in "${!tbl_list[@]}"
do
    echo "Restore $tbl to ${tbl_list[$tbl]}"
    # Extract the content between drop table and Table structure for, also replace the table name
    sed -n -e '/DROP TABLE IF EXISTS `'$tbl'`/,/\/*!40000 ALTER TABLE `'$tbl'` ENABLE KEYS \*\/;/p' $dump_file > tbl.sql
    sed -i 's/`'$tbl'`/`'${tbl_list[$tbl]}'`/g' tbl.sql
    mysql -h $db_host -u $db_user -p"$db_pass" $db_name < tbl.sql
    # Remove the temporariy table created
    rm -f tbl.sql
done
