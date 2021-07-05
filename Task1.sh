#!/bin/bash
if id "$1" &>/dev/null; then
    echo 'The user found:' $1
    if [ -d "$2" ]; then
        echo 'The directory exist:' $2
        sudo chown -R $1:$1 $2
    else
        echo 'The directory dosen`t exist:' $2
    fi
else
    echo 'user not found:' $1
fi
