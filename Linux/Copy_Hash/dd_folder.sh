#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")


SourcePath=/mnt/www_nfs/tk2/firaxis
DestPath=/mnt/temp_firaxis_dump/nfs_docroots/tk2_firaxis_20131010
logFile=/mnt/temp_firaxis_dump/nfs_docroots/tk2_firaxis_20131010/log.txt

#check to make sure dcfldd is installed
if ! type "dcfldd" > /dev/null; then
   echo "this script requires dcfldd, please install it."
   exit 1
fi

# copy command:  dcfldd if=/root/file.test of=/tmp/root/file.test hash=md5 hashlog=/tmp/hashlog.txt seek=0 skip=0
# awk command: awk '{ print $3 }' /tmp/hashlog.txt


/bin/mkdir -p "$DestPath"

echo "started copying $SourcePath to $DestPath" >> $logFile
echo "Start Time: `date`" >> $logFile
echo "--------------------------------------------------------------------------" >> $logFile
echo "Searching for files to copy, please wait...."
for f in `find $SourcePath -type f`
do
  echo copying $f
  #sHash=`md5sum "$f" | awk '{ print $1 }'`
  DestFile=`echo $DestPath/$f | sed 's/\/\//\//g'`
  DestDir=`dirname $DestFile`
  SourceDir=`dirname $f`
  /bin/mkdir -p "$DestDir" && chown --reference="$SourceDir" "$DestDir" && touch -r "$SourceDir" "$DestDir"
  dcfldd if="$f" of="$DestFile" hash=md5 hashlog=/tmp/hashlog.txt seek=0 skip=0 > /dev/null 2>&1 && chown --reference="$f" "$DestFile" && touch -r "$f" "$DestFile"
  if [ "$?" = "0" ]; then
     dHash=`md5sum "$DestFile" | awk '{ print $1 }'`
     sHash=`awk '{ print $3 }' /tmp/hashlog.txt`
     echo copied: $f source hash: $sHash dest hash: $dHash >> $logFile
  else
    echo failed: $f source hash: $sHash | tee -a "$logFile"
  fi
done;

IFS=$SAVEIFS
echo "--------------------------------------------------------------------------" >> $logFile
echo "Finish Time: `date`" >> $logFile
echo "Copied: `du -s "$DestPath" | awk '{ print $1 }'` bytes." | tee -a "$logFile"
