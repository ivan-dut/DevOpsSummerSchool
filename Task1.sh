#!/bin/bash

if id "$1" &>/dev/null; then
    echo 'Change user to:' $1
    if [ -d "$2" ]; then
        echo 'The directory exist:' $2
        if [ $UID -eq 0 ]; then 
            chown -R $1:$1 $2
        else
            echo "You must to be have ROOT to run this script"
        fi
    else
        echo 'The directory dosen`t exist:' $2
    fi
else
    echo 'user not found:' $1
fi
