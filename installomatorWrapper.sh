#!/bin/zsh

#installomatorWrapper.sh v.1.1

### USER CONFIGURATION ###

DEBUG=0

### Verify Input ###

if [ $# -eq 0 ]; then
	echo "No arguments provided. Exiting"
	exit 1
fi

###Log file variables setup

LOG_FOLDER=/usr/local/installomatorWrapper/logs
LOG_DATE=$(date +%Y-%m-%d_%H-%M-%S)

LOG_FILE="$LOG_FOLDER"/"$LOG_DATE"_installomatorWrapper.log
MANIFEST_FILE="$LOG_FOLDER"/"$LOG_DATE"_Manifest-installomatorWrapper.log

#Create log folder
if [ ! -d $LOG_FOLDER ]; then
	mkdir -p $LOG_FOLDER
	if [ $? != 0 ]; then
		echo "Failed to create log folder"
		exit 1
	fi
fi

#Rotate logs, keeping only 10 latest
LOG_ARRAY=( $( ls $LOG_FOLDER/*_Installomator.log | sort ) )

LOG_COUNT=0
LOG_MAX=10

#Count how many log files there are
for i in ${LOG_ARRAY[@]}; do
	LOG_COUNT=$((LOG_COUNT+1))
done

#If there are greater than LOG_MAX variable files, delete the oldest (sorting based on date)
if [ $LOG_COUNT -ge "$LOG_MAX" ] ; then
	echo "Rotating logs. Deleting file: ${LOG_ARRAY[1]}" >> $LOG_FILE 2>&1
	rm ${LOG_ARRAY[1]}
	if [ $? != 0 ]; then
		echo "Failed to rotate logs"
		exit 1
	fi
fi

touch $LOG_FILE
if [ $? != 0 ]; then
	echo "Failed to create "$LOG_FILE""
	exit 1
fi

touch $MANIFEST_FILE
if [ $? != 0 ]; then
	echo "Failed to create "$MANIFEST_FILE""
	exit 1
fi

#Test if Installomator is present

if [ ! -f /usr/local/Installomator/Installomator.sh ] ; then
	echo "FAIL: Installomator.sh NOT FOUND"
	echo ""$LOG_DATE": Installomator Fail - Script not installed" >> $MANIFEST_FILE
	exit 1
fi

#Update Installomator
/usr/local/Installomator/Installomator.sh installomator >> $LOG_FILE  2>&1
if [ $? != 0 ]; then
	echo "FAILED TO UPDATE INSTALLOMATOR"
	echo ""$LOG_DATE": Installomator failed to update" >> $MANIFEST_FILE
	exit 1
fi

#Install each app
for APPLICATION in "$@" 
do
    /usr/local/Installomator/Installomator.sh $APPLICATION >> $LOG_FILE  2>&1
    if [ $? != 0 ]; then
    	FAILED_APP_INSTALLS+=($APPLICATION)
		echo ""$LOG_DATE": Installomator Fail - "$APPLICATION" failed to install" >> $MANIFEST_FILE
    else
    	SUCCESSFUL_APP_INSTALLS+=($APPLICATION)
		echo ""$LOG_DATE": Installomator Success - "$APPLICATION" installed successfully" >> $MANIFEST_FILE
    fi
done


if [ $DEBUG = 1 ] ; then
	echo "Log File: "$LOG_FILE""
	for i in ${SUCCESSFUL_APP_INSTALLS[@]}; do
		echo "SUCCESS: "$i""
	done
fi

for i in ${FAILED_APP_INSTALLS[@]}; do
	echo "FAILED INSTALL: "$i""
done
