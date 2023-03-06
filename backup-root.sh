#!/bin/bash
[[ $(id -u) -eq 0 ]] || { echo "Superuser privilage required." ; exit 1; };

#configuration begin

#Filesystem UUID of external device
uuid="<uuid>"
#user whose directiry is to be backed up (please give name not id)
user="<user>"
#mountpoint of external device
mountpoint="/mnt"
#directory where bachup should be stored. cannot be empty
dir="backup"
# specify true if a gui prompt is required at the start and end of backup
gui="true"
# display backup notification on desktop? specify "true" for yes. display 0 must be active.
status_report="true"

#configuration end

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

if [[ -z "$user" ]]; then
	echo "\"\$user\" must be set" 1>&2;
	exit 1;
else
	id "$user" 1>/dev/null;
	[[ $? -ne 0 ]] && { echo "\"$user\" does not exist" 1>&2; exit 1; };

	user="$(id -nu "$user")"
fi

if [ "$gui" == "true" ]; then
	strmsg="$(printf "Start backup of %s to %s :" "/home/$user" "$(printf "$mountpoint/$dir" | tr -s '/')")"

	sudo -nu "$user" env DISPLAY=":0" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true dbus-launch \
		kdialog --title "Backup Confirmation" --dontagain backupscript:promptconfirm --warningcontinuecancel "$strmsg\npress continue to start backup"
	retcode=$?

	if [ $retcode -ne 0 ]; then
		sudo -nu "$user" env DISPLAY=":0" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true dbus-launch \
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

rm -f /tmp/backup-script-error.log
if [ "$status_report" == "true" ]; then

	env DISPLAY=":0" "$bup_run_exec" --directory="/home/$user" \
		--target-dir="$dir" --mountpoint="$mountpoint" --unmount \
		--user="$user" --report="$user" "$dev" 2>/tmp/backup-script-error.log
	code=$?
else
	"$bup_run_exec" --directory="/home/$user" \
	        --target-dir="$dir" --mountpoint="$mountpoint" --unmount \
	        --user="$user" "$dev" 2>/tmp/backup-script-error.log
	code=$?
fi
chown "$user":"$user" /tmp/backup-script-error.log
chmod a+r /tmp/backup-script-error.log

if [ $code -ne 0 ]; then
	echo "non zero exit code : $code" 1>&2;
	if [ "$gui" == "true" ]; then
		sudo -nu "$user" env DISPLAY=":0" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true dbus-launch \
			kdialog --title "Backup Script" --sorry \
			"Script returned with non zero exit status $code\nPlease check \"/tmp/backup-script-error.log\" for details." &
	fi
else
	if [ "$gui" == "true" ]; then
		sudo -nu "$user" env DISPLAY=":0" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true dbus-launch \
			kdialog --title "Backup Script" --sorry \
			"Script returned with exit status $code\nSuccessfully finished backing up!" &
	fi
fi

exit $code
