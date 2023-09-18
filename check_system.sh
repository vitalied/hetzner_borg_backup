#!/bin/bash -l

##
## Set environment variables
##

REPOSITORY_DIR="backups"
REPOSITORY_NAME="system"
BACKUP_FILE_PREFIX="${REPOSITORY_NAME}"
LOG="/var/log/backup/backup_${REPOSITORY_NAME}.log"

# Set in ~/.profile
# export BACKUP_USER="user"
# export BORG_PASSPHRASE="passphrase"

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO="ssh://${BACKUP_USER}@${BACKUP_USER}.your-storagebox.de:23/./${REPOSITORY_DIR}/${REPOSITORY_NAME}"
# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE=${BORG_PASSPHRASE}

borg info

borg check
