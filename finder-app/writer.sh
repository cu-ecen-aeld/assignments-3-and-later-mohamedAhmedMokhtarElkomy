#!/bin/sh

if [ $# -ne 2 ]
then
    #echo "error there is missing arguments"
    return 1
fi

writefile=$1
writestr=$2

dir=${writefile%/*} #Delete the shortest match of string from the end:

if ! [ -d $dir ]
then
    mkdir -p $dir
    
fi

echo $writestr > $writefile 

