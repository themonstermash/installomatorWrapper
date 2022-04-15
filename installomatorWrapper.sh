#!/bin/zsh

#installomatorWrapper.sh v.0.1.5

DEBUG=1

# No sleeping
/usr/bin/caffeinate -d -i -m -u &
caffeinatepid=$!
caffexit () {
    kill "$caffeinatepid"
    pkill caffeinate
    swift_dialog_command "quit:"
    exit $1
}

##Set styling for Swift Dialog
#Syntax: swift_dialog "title" "body of message" "additional options"
#Example: swift_dialog "Something Is Happening" "Something is going on. This is a description" --icon /Applications/Self-Service.app --iconsize 100
swift_dialog()
{

if [ -e /usr/local/bin/dialog ]; then
	/usr/local/bin/dialog --titlefont color="#a62524" --title "$1" --message "$2" --moveable\
	--icon "/Library/PreferencePanes/MonitoringClient.prefPane/Contents/Resources/MonitoringClient.icns" \
	$3 $4 $5 $6 $7 $8 $9 $10 $11 $12 $13 $14 $15 $16 $17 $18 $19 $20 $21 $22 $23 $24 $25 $26 $27 $28 $29 $30
	
	if [ $? = 2 ]; then
		exit 99
	fi

fi

}

##swiftDialog takes commands to anything piped to it's log file, this function utilizes that
swift_dialog_command()
{

if [ -e /usr/local/bin/dialog ]; then
	/bin/echo "$1" >> /var/tmp/dialog.log
fi

}

### Verify Input ###

if [ $# -eq 0 ]; then
	echo "No arguments provided. Exiting"
	caffexit 1
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
		caffexit 1
	fi
fi

#Rotate logs, keeping only 10 latest
LOG_ARRAY=( $( ls "$LOG_FOLDER"/*_installomatorWrapper.log | sort ) )

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
		caffexit 1
	fi
fi

#Create log
touch $LOG_FILE
if [ $? != 0 ]; then
	echo "Failed to create "$LOG_FILE""
	caffexit 1
fi

#Create manifest
touch $MANIFEST_FILE
if [ $? != 0 ]; then
	echo "Failed to create "$MANIFEST_FILE""
	caffexit 1
fi

#Test if Installomator is present

if [ ! -f /usr/local/Installomator/Installomator.sh ] ; then
	echo "FAIL: Installomator.sh NOT FOUND"
	echo ""$LOG_DATE": Installomator Fail - Script not installed" >> $MANIFEST_FILE
	caffexit 1
fi

##SCRIPT STARTS HERE##

swift_dialog "App Updates Needed" "This process typically takes about 15 minutes, and its a good idea to reboot after.\n\nPlease save and close any open documents before going forward.\n\nClick Continue with Updates to begin." --overlayicon "/System/Applications/App Store.app" --button1text "Continue with Updates" --button2text "Cancel"

#Set variable of number of apps to install, this is used for the progress bar
APP_COUNT=$#
APP_COUNT=$((APP_COUNT+1))
APP_COMPLETIONS=0

swift_dialog "Updating your apps" "Updates are in progress..." --progress $APP_COUNT --button1text "Hide this progress window" --overlayicon "/System/Applications/App Store.app" &

#Update Installomator

sleep 1
swift_dialog_command "progress: $APP_COMPLETIONS"
swift_dialog_command "progresstext: installomator"
sleep 10

/usr/local/Installomator/Installomator.sh installomator >> $LOG_FILE  2>&1
if [ $? != 0 ]; then
	echo "FAILED TO UPDATE INSTALLOMATOR"
	echo ""$LOG_DATE": Installomator failed to update" >> $MANIFEST_FILE
fi

#Install each app
for APPLICATION in "$@" 
do
    #Update swiftdialog progress bar and message
	swift_dialog_command "progress: $APP_COMPLETIONS"
    swift_dialog_command "progresstext: $APPLICATION"
    #For usability/viewing
    sleep 1
    /usr/local/Installomator/Installomator.sh $APPLICATION >> $LOG_FILE  2>&1
    if [ $? != 0 ]; then
    	FAILED_APP_INSTALLS+=($APPLICATION)
		echo ""$LOG_DATE": Installomator Fail - "$APPLICATION" failed to install" >> $MANIFEST_FILE
    else
    	SUCCESSFUL_APP_INSTALLS+=($APPLICATION)
		echo ""$LOG_DATE": Installomator Success - "$APPLICATION" installed successfully" >> $MANIFEST_FILE
    fi
    #Set completion variable for swiftdialog
    APP_COMPLETIONS=$((APP_COMPLETIONS+1))
    #For usability/viewing
    sleep 1
done

swift_dialog_command "quit:"

if [ $DEBUG = 1 ] ; then
	echo "Log File: "$LOG_FILE""
	for i in ${SUCCESSFUL_APP_INSTALLS[@]}; do
		echo "SUCCESS: "$i""
	done
fi

for i in ${FAILED_APP_INSTALLS[@]}; do
	echo "FAILED INSTALL: "$i""
done


#If there are no failed apps, give a good message. Otherwise inform the user.
if [ -z "$FAILED_APP_INSTALLS" ]; then
	swift_dialog "Updates Completed Successfully" "Thanks for helping keep your apps up to date. \n\nIf you have any issues or questions please submit a ticket to helpdesk@secondsonconsulting.com"  --overlayicon "/System/Applications/App Store.app" &
else
	swift_dialog "Don't panic!" "There was an issue updating the following apps: $FAILED_APP_INSTALLS.\n\nDon't Panic! Your apps are probably still usable, they just couldn't be updated for some reason.\n\nPlease launch and test.\n\nIf you're having issues with these applications please submit a ticket to helpdesk@secondsonconsulting.com"  --overlayicon "/System/Applications/App Store.app" &
fi

caffexit 0
