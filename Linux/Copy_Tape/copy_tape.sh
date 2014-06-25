#!/bin/bash
# Copy tapes using dcfldd
#
# assumptions:
#
# mt is installed
# dcfldd is installed
# 
# arguements:
#
# 1. source tape drive (nst0)
# 2. dest tape drive (nst1)
# 3. md5 log directory (per file)
# 4. block size 
#
########################################################### 
# Begin Program
###########################################################
# Get user input
#
sdrive="/dev/nst0"
ddrive="/dev/nst1"
echo "*************************************"
echo ""
echo "This program copies tapes"
echo ""
echo "assumptions:"
echo "* mt is installed"
echo "* you have at least one tape drive"
echo "* you have dcfldd installed"
echo ""
echo "*************************************"
echo ""
echo "Specify Source Drive (/dev/nst0):"
read sdrive
echo "Specify Destination Drive (/dev/nst1):"
read ddrive
echo "Specify directory for md5 hash logs ($HOME):"
read hashdir
echo "Specify block size (64k):"
read bsize
if [ "$sdrive" = "" ]; then 
	sdrive="/dev/nst0"
fi
if [ "$ddrive" = "" ]; then 
	ddrive="/dev/nst1"
fi
if [ "$hashdir" = "" ]; then 
	hashdir="$HOME"
fi
if [ "$bsize" = "" ]; then 
	bsize="64k"
fi

# Check the drive status.  Make sure that both drives are on FM 0; Blk: 0
sstatus=`mt -f $sdrive status`
if [ "$?" = "0" ]; then
	#echo "$sdrive status: ${sstatus#*$sdrive}"
	fmnum="${sstatus#*File number=}"
	fmnum="${fmnum:0:1}"
	blknum="${sstatus#*block number=}"
	blknum="${blknum:0:1}"
	echo "$sdrive on FM: $fmnum; Blk: $blknum"
	if [ "$fmnum" = "0" ] && [ "$blknum" = "0" ]; then
		echo "$sdrive is ready"
	else
		echo "rewinding tape..."
		mt -f $sdrive asf 0
		echo "$sdrive has been rewound and is on FM 0 and Blk 0...ready"
	fi
else
	echo "Error communicating with $sdrive"
	exit 1
fi 

dstatus=`mt -f $ddrive status`
if [ "$?" = "0" ]; then
	#echo "$ddrive status: ${dstatus#*$ddrive}"
	fmnum="${dstatus#*File number=}"
	fmnum="${fmnum:0:1}"
	blknum="${dstatus#*block number=}"
	blknum="${blknum:0:1}"
	echo "$ddrive on FM: $fmnum; Blk: $blknum"
	if [ "$fmnum" = "0" ] && [ "$blknum" = "0" ]; then
		echo "$ddrive is ready"
	else
		echo "rewinding tape..."
		mt -f $ddrive asf 0
		echo "$ddrive has been rewound and is on FM 0 and Blk 0...ready"
	fi
else
	echo "Error communicating with $ddrive"
	exit 1
fi 

# check to make sure specified log directory exists.  
# if it does not exist attempt to create.

if [ -d $hashdir ]; then
	echo "Hash log directory exists"
else
	#echo "hashdir = $hashdir"
	mkdir "$hashdir"
	if [ "$?" = "0" ]; then
		echo "Hash log directory successfully created"
	else
		echo "Error creating hash log directory"
		exit 1
	fi
fi

# Execute dcfldd in loop.  
# Execute an mt status command on $sdrive to see if EOT flag is reached
# Increment file number and create and md5 log of each filemark

echo "Copying $sdrive to $ddrive..."

flnum=1
tapestatus=""
ddstatus=""
while [ "$tapestatus" != "EOT" ]; do
	echo "Copying Filemark $((flnum -1))..."
	dcfldd if=$sdrive of=$ddrive hash=md5 hashlog=$hashdir/file${flnum##0}_md5.txt status=on bs=$bsize conv=noerror
	
	# check to see if dd resulted in +0 status
	#if [ "$ddstatus2" = "0" ]; then
	#echo "ddstatus: $?"
	if [ "$?" = "0" ]; then #if successful completion
		echo "copied Filemark $((flnum - 1))"
		hashvar=`cat "$hashdir/file${flnum##0}_md5.txt"`
		hashvar="${hashvar#*Total (md5): }"
		echo "Filemark $((flnum -1)) hash: $hashvar"
		sstatus=`mt -f $sdrive status`
		# check mt status for EOT or EOD flag
		status2="${sstatus#*EOD}"
		status3="${sstatus#*EOT}"
		status2="${status2:0:1}"
		status3="${status3:0:1}"
		if [ "$status2" = " " ] || [ "$status3" = " " ]; then
			#echo "$sstatus"
			echo "End of Tape or End of Data encountered"
			echo "Copy finished"
			tapestatus="EOT"
			exit 0
		fi 
	else	
		echo "Copying filemark $((flnum - 1)) resulted in errors"
		echo "Try changing the block size"
		echo $ddstatus
		exit 1
	fi
	
	flnum=$((flnum + 1))

done
printf "\a"
printf "\a"
printf "\a"
exit 0

#
# SCSI 2 tape drive:
# File number=6, block number=0, partition=0.
# Tape block size 0 bytes. Density code 0x1b (DLT 35GB).
# Soft error count since last status=0
# General status bits on (85010000):
#  EOF WR_PROT ONLINE IM_REP_EN

