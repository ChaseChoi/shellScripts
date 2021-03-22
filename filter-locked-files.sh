#!/bin/bash

if [[ $# -eq 1 ]]; then
    timestamp=`date +%H_%M_%S`
    cd "$1"
    locked_files=`ls -lO | tr -s " " | cut -d " " -f 5,10 | egrep "uchg" | cut -d " " -f 2`

    if [[ -n $locked_files ]]; then
        mkdir $timestamp
        for file in $locked_files; do
            # remove uchg flag
            chflags nouchg $file
            mv $file $timestamp
            echo "Move $file to $timestamp"
        done
    fi
fi