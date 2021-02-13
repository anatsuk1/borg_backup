# JxyMemories

# IMPORTANT

## NOW UNDER DEVELOPMENT

**I feel that `jxy-memories.py` is almost okay but has a trivial bug caused by lvm commands.**

I only finished cheking `jxy-memories.py`. Some checks still remains.

I will update this documentation after finishing development.


# Overview
JxyMemories is a backup script written in Python3 language.

JxyMemories has the one script and two systemd unit files.

## Script

jxy-memories.py is the backup script that snapshots, mounts, backups, unmounts, and removes two LVM LV volumes.
In addition to it maintains the backups during 24 hours, 31 days, 104 weeks(2 years), others are pruned.

# Usage

## Custom

**Change Variables to your environment.**

My environment is:
<pre>
Borg Repository: /var/borg/repo.borg
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

Rename the passphrase file to .borg-passphrase
```bash
mv example.borg-passphrase .borg-passphrase
```
Change invalid characters in `.borg-passphrase` to your password on Borg repository.
Such as from `xxxxxxxx` to `<your password>`.

Copy the backup script file and to the path.
```bash
cp jxy-memories.py .borg-passphrase /usr/local/etc/
```

Copy the systemd unit files to the systemd path.
```bash
cp jxy-memories.service jxy-memories.timer /etc/systemd/system
```
Enable and start
```
systemctl enable --now borg-backup.timer
```

## Thanks
Borg developers' GitHub page.
- @borgbackup https://github.com/borgbackup/borg
