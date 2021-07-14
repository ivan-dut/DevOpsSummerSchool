#!/bin/bash
  
#______________________
#Constants
DB_NAME=moodle_db

# Generating file name
echo "Genereting dump of $DB_NAME database"
curdatetime=`date +%d%m%Y_%H%M`
FILENAME_PREFIX=$DB_NAME"_"
filename=$FILENAME_PREFIX$curdatetime".sql"

#check if mysql service is running
mysql=`systemctl status mysql | grep running`
if [[ ${#mysql}]] == 0 ]];
then
    echo "The MySQL service is not running"
    exit 1
else
    # Create dump database
    mysqldumpresult= mysqldump --defaults-extra-file=~/tuhes/config.cnf $DB_NAME --no-tablespaces > /home/ubuntu/tuhes/$filename
    echo "Created dump $mysqldumpresult"
fi
