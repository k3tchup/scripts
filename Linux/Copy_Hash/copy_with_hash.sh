#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

SourcePath=/home/me
DestPath=/tmp
logFile=/tmp/log.txt


for f in `find $SourcePath -type f`
do
  echo copying $f
  sHash=`md5sum "$f" | awk '{ print $1 }'`
  DestFile=`echo $DestPath/$f | sed 's/\/\//\//g'`
  DestDir=`dirname $DestFile`
  mkdir -p $DestDir
  cp -p "$f" "$DestFile"
  if [ "$?" = "0" ]; then
     dHash=`md5sum "$DestFile" | awk '{ print $1 }'`
     echo copied: $f source hash: $sHash dest hash: $dHash >> $logFile
  else
    echo failed: $f source hash: $sHash
  fi
done;

IFS=$SAVEIFS
