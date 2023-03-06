#!/bin/bash

[[ $(id -u) -eq 0 ]] && {
	echo "This script is not optimised to run as root, Doing so will currupt repository" 1>&2 ;
	echo "Aborting.., Use backup-root.sh instead" 1>&2;
	exit 1;
};
#please keep same configuration as backup-root.sh
#this script is optimised to be run non interactive
#for this script to work;
# display 0 (DISPLAY=:0) must be up and running
# mountpoint should have traverse permission for user
# user must be able to mount
# backup directory (dir) must exist and have read write permissions for user
#
#if mountpoint is set up with traverse for user, the script backup-root.sh will setup the backup directory.
#

#configuration begin

#Filesystem UUID of external device
uuid="<uuid>"
#mountpoint of external device. overriden by fstab
mountpoint="/mnt"
#directory where bachup should be stored. cannot be empty
dir="backup"
# specify true if a gui prompt is required at the start and end of backup
gui="true"
# display backup notification on desktop? specify "true" for yes. display 0 must be active.
status_report="true"

#configuratuin end

#user whose directory is to be backed up
#requres root permission to be set to any other user that is than the current user...
#use basckup-root.sh instead as it is optimised to run as root.
user="$(id -nu)"


dev=$(lsblk -no UUID,PATH | awk "/^$uuid/ { print \$NF } ")
[[ -z "$mountpoint" ]] && mountpoint="/mnt"
[[ -z "$dir" ]] && dir="bup/"
[[ "$status_report" == "true" ]] && gui="true"

if [[ -z "$uuid" ]]; then
	echo "uuid=\"$uuid\" is empty" 1>&2;
	exit 1;
else
	[[ -b "$dev" ]] || { echo "uuid=\"$uuid\" is not assosiated with any block device" 1>&2 ; exit 1; };
fi

if [ "$gui" == "true" ]; then
	strmsg="$(printf "Start backup of %s to %s :" "/home/$user" "$(printf "$mountpoint/$dir" | tr -s '/')")"

	env DISPLAY=":0" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true dbus-launch \
		kdialog --title "Backup Confirmation" --dontagain backupscript:promptconfirm --warningcontinuecancel "$strmsg\npress continue to start backup"
	retcode=$?

	if [ $retcode -ne 0 ]; then
		env DISPLAY=":0" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true dbus-launch \
			kdialog --title "Backup Script" --msgbox \
			"You canceled the backup" & \
		exit $retcode;
	fi

	unset retcode;
	unset strmsg;
fi

bup_run_exec="$(which bup-run.sh)";
which bup-run.sh || { echo "bup-run.sh not found" 1>&2; exit 1; } &&
[ -x "$bup_run_exec" ] || { echo "bup-run.sh not executable" 1>&2; exit 1; };

if [[ "$status_report" == "true" ]]; then
	env DISPLAY=":0" "$bup_run_exec" --directory="/home/$user" \
		--target-dir="$dir" --mountpoint="$mountpoint" --unmount \
		--report="$user" "$dev" 2>/tmp/backup-script-error.log
	code=$?
else
	"$bup_run_exec" --directory="/home/$user" \
        	--target-dir="$dir" --mountpoint="$mountpoint" --unmount \
        	"$dev" 2>/tmp/backup-script-error.log
	code=$?
fi
chmod a+r /tmp/backup-script-error.log

if [ $code -ne 0 ]; then
	echo "non zero exit code : $code" 1>&2;
	if [ "$gui" == "true" ]; then
		env DISPLAY=":0" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true dbus-launch \
			kdialog --title "Backup Script" --sorry \
			"Script returned with non zero exit status $code\nPlease check \"/tmp/backup-script-error.log\" for details." &
	fi
else
	if [ "$gui" == "true" ]; then
		env DISPLAY=":0" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true dbus-launch \
			kdialog --title "Backup Script" --msgbox \
			"Script returned with exit status $code\nSuccessfully finished backing up!" &
	fi
fi
exit $code
