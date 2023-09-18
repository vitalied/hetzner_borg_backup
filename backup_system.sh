#!/bin/bash -l

##
## Set environment variables
##

REPOSITORY_DIR="backups"
REPOSITORY_NAME="system"
ARCHIVE_NAME_PREFIX="${REPOSITORY_NAME}"
LOG="/var/log/backup/backup_${REPOSITORY_NAME}.log"

# Set in ~/.profile
# export BACKUP_USER="user"
# export BORG_PASSPHRASE="passphrase"

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO="ssh://${BACKUP_USER}@${BACKUP_USER}.your-storagebox.de:23/./${REPOSITORY_DIR}/${REPOSITORY_NAME}"
# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE=${BORG_PASSPHRASE}

# some helpers and error handling:
asterisk_separator() { echo '******************************************************************************'; }
dash_separator() { echo '------------------------------------------------------------------------------'; }
info() { printf "\n%s %s\n\n" "$( date +"%Y-%m-%d %H:%M:%S" )" "$*" >&2; }
trap 'echo $( date +"%Y-%m-%d %H:%M:%S" ) Backup interrupted >&2; exit 2' INT TERM

##
## Output to a logfile
##

exec > >(tee -i -a ${LOG})
exec 2>&1

asterisk_separator
asterisk_separator

info "Starting backup"

# Backup the most important directories into an archive which name is prefixed with '{ARCHIVE_NAME_PREFIX}':

borg create                                         \
    --verbose                                       \
    --filter AME                                    \
    --list                                          \
    --stats                                         \
    --show-rc                                       \
    --compression zstd,22                           \
                                                    \
    --exclude-caches                                \
    --exclude 'home/*/.cache/*'                     \
    --exclude 'var/cache/*'                         \
    --exclude 'var/tmp/*'                           \
    --exclude /dev                                  \
    --exclude /proc                                 \
    --exclude /sys                                  \
    --exclude /var/run                              \
    --exclude /run                                  \
    --exclude /mnt                                  \
    --exclude /tmp                                  \
    --exclude /lost+found                           \
                                                    \
    --exclude /srv/VBox                             \
                                                    \
    ::${ARCHIVE_NAME_PREFIX}'_{now:%Y-%m-%d_%H:%M}'  \
    /

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 30 daily, 4 weekly and 12 monthly archives of THIS repository.
# The '{ARCHIVE_NAME_PREFIX}*' matching is very important to limit prune's operation to this
# repository's archives and not apply to other repositories' archives also:

borg prune                                    \
    --list                                    \
    --verbose                                 \
    --show-rc                                 \
    --keep-daily    30                        \
    --keep-weekly   4                         \
    --keep-monthly  12                        \
    --glob-archives "${ARCHIVE_NAME_PREFIX}*"  \

prune_exit=$?

# Actually free repo disk space by compacting segments.
info "Compacting repository"

# Use the `compact` subcommand to free repository space by compacting segments:

borg compact           \
    --verbose          \
    --cleanup-commits

compact_exit=$?

# Use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))
global_exit=$(( compact_exit > global_exit ? compact_exit : global_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup, Prune, and Compact finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup, Prune, and/or Compact finished with warnings"
else
    info "Backup, Prune, and/or Compact finished with errors"
fi

dash_separator
echo
echo

exit ${global_exit}
