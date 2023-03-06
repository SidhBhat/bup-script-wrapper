# bup-script-wrapper

This is a wrapper script for [bup-script](https://github.com/SidhBhat/bup-script), I use to backup
my home directory to another partition on a daily basis. These are the scripts I call from
[crontab](https://en.wikipedia.org/wiki/Cron).

## Installation

Installing these scripts is as simple as copying them to your system:

```bash
curl -sL https://raw.githubusercontent.com/SidhBhat/bup-script-wrapper/main/backup.sh > backup.sh
curl -sL https://raw.githubusercontent.com/SidhBhat/bup-script-wrapper/main/backup-root.sh > backup-root.sh
```

## Using The Wrapper Scripts

To use these scripts you have to venture inside the files and set the variables as instruted by the comments.

Note: This script backs up your home directory to another partition only. You cannot use it to backup to a
simple folder.

## Note for the developer

This project was actually part of the [bup-script](https://github.com/SidhBhat/bup-script) project. I decided
to seperate it and let [bup-script](https://github.com/SidhBhat/bup-script) focus only on the backup process.
You will find early development of these scripts in the [bup-script](https://github.com/SidhBhat/bup-script)
repo.

## Contributing

You can simply start by creating a pull request. If you have Improvement suggestions you can contact me by email.
