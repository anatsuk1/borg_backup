# borg_backup
The backup script for borg in shell language and two the systemd unit files.

# Overview

## Script

backup_by_borg.sh is the script that snapshots, mounts, backups, unmounts, and removes two LVM LV volumes.
In addition to it maintains the backups during 24 hours, 31 days, 104 weeks(2 years), others are pruned.

# Usage

## Custom

**Change Variables to your environment.**

My environment is:
<pre>
Borg Rpository: /var/borg/repo.borg
VG Name: ubuntu-vg
First LV Name: ubuntu-lv
Second LV Name: archive
</pre>

Variables in my script is:
<pre>
BORG_DIR="/var/borg/repo.borg"
VG_DIR="/dev/ubuntu-vg/"
ARCHIVE_NAME="archive"
UBUNTU_NAME="ubuntu-lv"
</pre>

**Change Variables according to your preference.**

Variables in my script is:
<pre>
MNT_DIR="/var/"
SNAP_NAME="-borgsnapshot"
</pre>

## Deploy

Change characters in `.borg-passphrase` to your password on Borg repository, such as from `xxxxxxxx` to `<your password>`.

Copy the backup script file and to the path.
```bash
cp backup_by_borg.sh .borg-passphrase /usr/local/etc/
```

Copy the systemd unit files to the systemd path.
```bash
cp borg-backup.service borg-backup.timer /etc/systemd/system
```
Enable and start
```
systemctl enable --now borg-backup.timer
```
