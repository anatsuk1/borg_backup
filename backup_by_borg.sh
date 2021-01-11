#!/bin/sh

# Copyright (c) 2021, anatsuk1
# All rights reserved.

# BSD 2-Clause License
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# Get password from passphrase files in the directory of this command.
export BORG_PASSCOMMAND="cat $(dirname $0)/.borg-passphrase"

### some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; tear_down; exit 2' INT TERM


### Declare variables
# For Borg
BORG_DIR="/var/borg/repo.borg"

VG_DIR="/dev/ubuntu-vg/"
MNT_DIR="/var/"

SNAP_NAME="-borgsnapshot"
ARCHIVE_NAME="archive"
UBUNTU_NAME="ubuntu-lv"


### Define functions
# $1 lv name, you can find it by lvdisplay command.
# $2 Percent of free space for snapshot size.
mount_lv() {
    local name=$1${SNAP_NAME}

    mkdir ${MNT_DIR}${name}
    lvcreate -s -l $2%FREE -n ${name} ${VG_DIR}$1
    mount -r -t ext4 ${VG_DIR}${name} ${MNT_DIR}${name}
}

# $1 lv name, you can find it by lvdisplay command.
umount_lv() {
    local name=$1${SNAP_NAME}

    umount -f ${VG_DIR}${name}
    lvremove -f ${VG_DIR}${name}
    rmdir ${MNT_DIR}${name}
}

# tear down
tear_down() {
    umount_lv ${ARCHIVE_NAME}
    umount_lv ${UBUNTU_NAME}
}

# borg create warapper
# $1 lv name, you can find it by lvdisplay command.
create_backup() {
    local source=${MNT_DIR}$1${SNAP_NAME}

    borg create                                 \
        --verbose                               \
        --filter AME                            \
        --list                                  \
        --stats                                 \
        --show-rc                               \
        --compression lz4                       \
        --one-file-system                       \
        --exclude-caches                        \
        --exclude ${source}'swap.img'           \
        --exclude ${source}'/root/.cache'       \
        --exclude ${source}'/home/*/.cache/*'   \
        --exclude ${source}'/var/cache/*'       \
        --exclude ${source}'/var/tmp/*'         \
                                                \
        ${BORG_DIR}::'{hostname}-'$1'-{now}'    \
        ${source}                               \

    return $?
}

# borg prune warapper
# 24 hours, 31 days, 104 weeks(2 years) backups are kept.
# $1 lv name, you can find it by lvdisplay command.
prune_backup() {
    borg prune                          \
        --list                          \
        --prefix '{hostname}-'$1        \
        --show-rc                       \
        --keep-hourly  24               \
        --keep-daily   31               \
        --keep-weekly  104              \
        ${BORG_DIR}                     \

    return $?
}


### Start script

info "Starting backup"

# Create and mount snapshot
mount_lv ${ARCHIVE_NAME} "50"
mount_lv ${UBUNTU_NAME} "100"

# Create backup
create_backup ${ARCHIVE_NAME}
archive_backup_exit=$?

create_backup ${UBUNTU_NAME}
ubuntu_backup_exit=$?

backup_exit=$(( archive_backup_exit > ubuntu_backup_exit ? archive_backup_exit : ubuntu_backup_exit ))

# Unmount and remove snapshot
tear_down

info "Pruning repository"

prune_backup ${ARCHIVE_NAME}
prune_backup ${UBUNTU_NAME}

prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup and Prune finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup and/or Prune finished with warnings"
else
    info "Backup and/or Prune finished with errors"
fi

exit ${global_exit}
