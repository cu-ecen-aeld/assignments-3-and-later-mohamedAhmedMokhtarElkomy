#!/bin/sh

if [ $# -ne 2 ]
then
    echo "error there is missing arguments"
    return 1
fi

filesdir=$1
searchstr=$2

if [ -d $filesdir ]
then

    countFiles=$(find $filesdir | wc -l)
    # countMatches=$(find $filesdir -name *$searchstr* | wc -l)

    tmpDir="$filesdir/*"
    countMatches=$(grep -c $searchstr $tmpDir | wc -l)

    countFiles=$((countFiles-1))

    echo "The number of files are $countFiles and the number of matching lines are $countMatches"

else
    echo "Directory not found"
    return 1
fi


