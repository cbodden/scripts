#!/bin/bash

#######################
#### user settings ####
#######################

INITIAL_ACTION="`echo $1 | tr '[A-Z]' '[a-z]'`"
RSYNC_ACTION="`echo $2 | tr '[A-Z]' '[a-z]'`"
RSYNC_RUN="`which rsync`"
RSYNC_OPTIONS="--archive --verbose --compress --progress --exclude '*swp'"
RSYNC_OPTIONS_CRON="--archive --compress --exclude '*swp'"
SERVER_NAME_CRON=
SERVER_PATH=
LOCAL_BASE_PATH=$HOME
REMOTE_BASE_PATH=
SERVER_USER_CRON=
FILE_LOOP_PATH="
"

#############################################
# nothing has to be changed below this line #
#############################################

#### function F_CRON ####

function F_CRON () 
{ 
    if [ "$RSYNC_ACTION" = "backup" ]; then
        for FILE_LOOP_TXT in $FILE_LOOP_PATH
            do
                $RSYNC_RUN $RSYNC_OPTIONS_CRON $LOCAL_BASE_PATH/$FILE_LOOP_TXT $SERVER_USER_CRON@$SERVER_NAME_CRON:$REMOTE_BASE_PATH/$SERVER_PATH/$FILE_LOOP_TXT
            done
        else
            if [ "$RSYNC_ACTION" = "restore" ]; then
                for FILE_LOOP_TXT in $FILE_LOOP_PATH
                    do
                        $RSYNC_RUN $RSYNC_OPTIONS_CRON $SERVER_USER_CRON@$SERVER_NAME_CRON:$REMOTE_BASE_PATH/$SERVER_PATH/$FILE_LOOP_TXT $LOCAL_BASE_PATH/$FILE_LOOP_TXT
                    done
            fi
    fi  

    exit 0
}
#### function F_LOCAL ####

function F_LOCAL () 
{
    clear

    #if [ "$2" = "backup" ]; then
    if [ "$RSYNC_ACTION" = "backup" ]; then
            printf "\nthis script a backup of:\n$FILE_LOOP_PATH\nfrom:\n$LOCAL_BASE_PATH\n\n"
                    else
                            printf "\nthis script runs a restore of:\n$FILE_LOOP_PATH\nfrom:\n$REMOTE_BASE_PATH\n\n"
    fi
    
    read -p "are you sure you want to continue ?   [yes|no]: " AWARE
    AWARE_FIXED="`echo $AWARE | tr '[A-Z]' '[a-z]'`"
    if [ -z "$AWARE_FIXED" ] || [ "$AWARE_FIXED" = "no" ] || [ "$AWARE_FIXED" != "yes" ]; then
            exit 1
    fi

    read -p "Type the server address, followed by   [ENTER]: " SERVER_NAME
    read -p "Type the username, followed by         [ENTER]: " SERVER_USER

    if [ "$RSYNC_ACTION" = "backup" ]; then
        for FILE_LOOP_TXT in $FILE_LOOP_PATH
            do
                $RSYNC_RUN $RSYNC_OPTIONS $LOCAL_BASE_PATH/$FILE_LOOP_TXT $SERVER_USER@$SERVER_NAME:$REMOTE_BASE_PATH/$SERVER_PATH/$FILE_LOOP_TXT
            done
        else
            if [ "$RSYNC_ACTION" = "restore" ]; then
                for FILE_LOOP_TXT in $FILE_LOOP_PATH
                    do
                        $RSYNC_RUN $RSYNC_OPTIONS $SERVER_USER@$SERVER_NAME:$REMOTE_BASE_PATH/$SERVER_PATH/$FILE_LOOP_TXT $LOCAL_BASE_PATH/$FILE_LOOP_TXT
                    done
            fi
    fi

    exit 0
}

#### actions ####

if [ $# -lt 2 ]; then
    clear
    printf "missing switches\n"
    printf "\ncommand is run $0 <cron|local> <backup|restore>\n"
    printf "cron is less verbose with settings edited in file\n"
    printf "local is verbose with interactive settings\n\n"
    exit
fi

if [ "$INITIAL_ACTION" != "cron" ] && [ "$INITIAL_ACTION" != "local" ]; then
    clear
    printf "\nsyntax error. should be $0 <cron|local> <backup|restore>\n\n"
    exit
        else
            if [ "$RSYNC_ACTION" != "backup" ] && [ "$RSYNC_ACTION" != "restore" ]; then
                    clear
                    printf "\nsyntax error. should be $0 <cron|local> <backup|restore>\n\n"
                    exit
            fi
fi

if [ "$INITIAL_ACTION" = "cron" ]; then
    F_CRON ## function F_CRON
    else
        if [ "$INITIAL_ACTION" = "local" ]; then
            F_LOCAL ## function F_LOCAL
        fi
fi
# vim:set ts=4 sw=4 noexpandtab:
