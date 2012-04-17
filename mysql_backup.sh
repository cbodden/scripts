#!/bin/bash

DIRP=/home/lgarion/site_bak/
DATE=$(date +"%m-%d-%y")
MYSQL_SERVER_REMOTE=
MYSQL_SERVER_LOCAL=
USER=
PASSWORD_REMOTE=''
PASSWORD_LOCAL=''
# LOOP_VAR="wordpress_test lotgd ilts_wp"
LOOP_VAR="lotgd ilts_wp"
TGZ=${DIRP}mysql/*tgz

for LOOP_VAR_TXT in $LOOP_VAR
  do
    LOOP_VAR_FILE=${DIRP}mysql/poa_${LOOP_VAR_TXT}.${DATE}.sql
    LOOP_VAR_DB=pissedoffadmins_$LOOP_VAR_TXT
    /usr/bin/mysqldump --user=$USER --password=$PASSWORD_REMOTE --host=$MYSQL_SERVER_REMOTE $LOOP_VAR_DB > $LOOP_VAR_FILE
    /usr/bin/mysql --user=$USER --password=$PASSWORD_LOCAL --host=$MYSQL_SERVER_LOCAL  $LOOP_VAR_DB < $LOOP_VAR_FILE
    /usr/bin/tar -czvf ${LOOP_VAR_FILE}.tgz $LOOP_VAR_FILE
    rm $LOOP_VAR_FILE
  done

# find $TGZ -mtime +6 -exec rm -f {} \;
# find ~/site_bak/mysql/ -mtime +6 -ctime +6 -exec rm -f {} \;
# find ~/site_bak/mysql/ -mtime +6 -exec rm -f {} \;
## 6 days
find ~/site_bak/mysql/ -cmin +8640 -exec rm -f {} \;
