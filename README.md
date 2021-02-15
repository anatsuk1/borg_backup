# JxyMemories

JxyMemories is a backup script written in Python3 language.

# Overview

JxyMemories consist of one Python3 script and two systemd unit files.

The feature of JxyMemories:
- Backup logical volume of LVM.
- Prune the old backups automately.
- Show information of the backups.
- Continuously backup on `systemd` timer.

You can restore logical volume of LVM from the backups in BorgBackup repository, of course you can restore a file from the backups.

## Python3 Script

"Backup" feature of jxy-memories.py:
- Create the snapshot from logical volume of LVM.
- Mount the snapshot at everwhere.
- Backup the the snapshot mounted.

"Prune" feature of jxy-memories.py:
- Prune the earlier backups except the later backups.

## systemd unit files.

Provide systemd unit file for Interval Timer.
- jxy-memories.timer is systemd timer unit.
- jxy-memories.service is systemd sevice unit.

# Usage

## Configure

The configuration features in JxyMemories.


### Configure JxyMemories

`jxy-memories.py` has many configuration variable in its own source.

Let's assigne your configuration to Name of variable!


### Explain JxyMemories configururations

Explain configure with name, description and initial configuration:
|Name|Description|Initial Configuration|
|---|---|---|
|LOGICAL_VOLUMES|Tuple of logical volumes specified LV Path and filesystem type.|See below **Complex Initial Configuration**|
|BXXG_REPOSITORY|Path to BorgBackup repository|`"/var/borg/repo.borg"`|
|BXXG_PASS_PHRASE|Name of file containing passphrase accessing to repository|`".borg-passphrase"`|
|BXXG_PRUNE_KEEP_NUMBERS|The numbers of keeping latest archives related to times when JxyMemories prunes|See below **Complex Initial Configuration**|
BXXG_EXCLUDE_PATTERNS|The patterns that JxyMemories excludes files from backup archives|See below **Complex Initial Configuration**|

### Complex Initial Configuration

**LOGICAL_VOLUMES**

LOGICAL_VOLUMES is an array of which an element conatains LV Path and filesystem type.
An element contains LV Path at the first element, filesystem type at the second element.

Pick up LV Path and filesystem type from the output of `lvdisplay` and `df -T` commands.

Initial Configuration is:
```python3::jxy-memories.py
(
    # LV Path,                   filesystem type
    ("/dev/ubuntu-vg/archive",   "ext4"),
    ("/dev/ubuntu-vg/ubuntu-lv", "ext4"),
)
```

**BXXG_PRUNE_KEEP_NUMBERS**

BXXG_PRUNE_KEEP_NUMBERS is a dictoinary of which an element conatains `--keep-<interval>` of `borg prune` optional arguments.
An element contains `--keep-<interval>` string itself at Key, `--keep-<interval>` parameter at Value.

`borg prune --help` with more details.

Initial Configuration is:
```python3::jxy-memories.py
{
    "--keep-secondly": 0,
    "--keep-minutely": 0,
    "--keep-hourly": 24,
    "--keep-daily": 31,
    "--keep-weekly": 104,
    "--keep-monthly": 0,
    "--keep-yearly": 0,
}
```

**BXXG_EXCLUDE_PATTERNS**

BXXG_EXCLUDE_PATTERNS is an array which conatains Exclude Pattern.
JxyMemories excludes paths matching Exclude Pattern.
JxyMemories will combine the mount point to lvm snapshot with Exclude Pattern if Exclude Pattern is absolute path.

`borg create --help` with more details.

Initial Configuration is:
```python3::jxy-memories.py
(
    "/swap.img",
    "/root/.cache",
    "/home/*/.cache/*",
    "/var/cache/*",
    "/var/tmp/*",
)
```

## Advanced Configure

```
######################
# Advanced Configure #
######################
DEBUG_DRY_RUN: Final[bool] = False
LOGGER: Final[Logger] = logging.getLogger(__name__)
LOGGER_LOG_LEVEL: Final[int] = logging.INFO
LOGGER_LOG_FILENAME: Final[str] = "/var/log/jxymemories.log"

# The base directory where JxyMemories mounts lvm snapshot.
MOUNT_BASE_DIRECTORY: Final[str]  = "/"

# The snapshot postfix with which JxyMemories combine LV Name.
SNAPSHOT_POSTFIX: Final[str] = "-jxy"

#
# Linux Commands
#

# Pass str.format with the following command and variables.
# str.format replace "{}" in the command to variables.

# Replace `{}` to mount path of snapshot LV.
MKDIR: Final[str]  = "mkdir -p {}"
# Replace `{}` to mount path of snapshot LV.
RMDIR: Final[str]  = "rmdir {}"

# Replace 1st `{}` to snapshot LV Name, 2nd `{}` LV Path of backup.
LVCREATE_SNAPSHOT: Final[str]  = "lvcreate -s -l 100%FREE -n {} {}"
# Replace `{}` to mount path of snapshot LV.
LVREMOVE: Final[str]  = "lvremove -f {}"

# Replace 1st `{}` to filesystem type, 2nd `{}` to snapshot LV Path, 3rd `{}` to mount path of snapshot LV.
MOUNT: Final[str]  = "mount -r -t {} {} {}"
# Replace `{}` to mount path of snapshot LV.
UMOUNT: Final[str]  = "umount -f {}"
```


## Deploy

Create the passphrase file containing your passphrase to access BorgBackup repository.
```bash
echo <your passphrase on BorgBackup> > .borg-passphrase
```

Copy `jxy-memories.py` and the passphrase file to `/usr/local/etc/` directory.
```bash
sudo cp jxy-memories.py .borg-passphrase /usr/local/etc/
```

Copy the systemd unit files to the systemd directory.
```bash
cp jxy-memories.service jxy-memories.timer /etc/systemd/system
```

Enable and start schedule timer.
```
systemctl enable --now borg-backup.timer
```

## Environment

JxyMemories is running but not limited with the followings.

- Ubuntu: 20.10 Server
- LVM: 2.03.07(2) (2019-11-30)
- Python: 3.8.6
- BorgBuckup: 1.1.15

## For your convience

### Backup Repository
JxyMemories depends on BorgBackup. Prepare BorgBackup repository.

```bash
sudo borg init -e repokey /var/borg/repo.borg
```

The command means initialize BorgBackup repository with passphrase.

See more details, if you need, at [Easy To Ese on Official BorgBackup repository](https://github.com/borgbackup/borg/blob/master/README.rst#easy-to-use)

### Mount Backups
Mount Backup Repository of fuse.borgfs filesystem type.

Install libfuse on your Distoribution once.
```bash
sudo apt install libfuse-dev
```

Mount Repository of fuse.borgfs filesystem type at `<mount point>`.
```bash
sudo mount -r -o allow_other -t fuse.borgfs /var/borg/repo.borg/ <mount point>
```

## Thanks
Borg developers' GitHub page.
- @borgbackup https://github.com/borgbackup/borg

@ThomasWaldmann's feedback that using BORG_xxxxxx env variable name risks collisions to BorgBuckup.
-  https://github.com/ThomasWaldmann