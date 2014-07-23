#!/usr/bin/zsh --sh-word-split

ANNEX=~/annex
BACKUPS=backups
DEST_DIR="$ANNEX/$BACKUPS"
DEFAULT_SRC=~/annex

####################################################################################################
# Helper functions
####################################################################################################

# Evals or simulates a string based on the --simulate flag
function evalOrSimulate {
    if [ ${FLAGS_simulate} -eq ${FLAGS_TRUE} ]; then
        log "$1"
    else
        eval $1 >&2
    fi
}

function log { echo -e "$1" >&2 }
function logSectionTitle { log "\n$1:" }
function logKeyValue { log "$1 -> $2" }

function error {
    log "error: $1"
    exit 1
}

####################################################################################################
# Argument parsing
####################################################################################################

# Source shflags (https://code.google.com/p/shflags/wiki/Documentation10x)
FLAGS_PARENT=$0
. shflags

# Configure shflags
DEFINE_boolean 'overwrite' false 'overwrite existing archive' 'o'
DEFINE_boolean 'simulate' false 'simulate results without archiving' 's'

# Parse flags & options
FLAGS_HELP="USAGE: $0 [flags] [dirs]"
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

# Parse srouce
if [[ $# < 1 ]]; then
    SRCS=$DEFAULT_SRC
else
    SRCS="$@"
fi

####################################################################################################
# Backup
####################################################################################################

# Calculate a prefix to remove from each base (e.g., "_home_jamie_annex")
PREFIX=$(readlink -e $ANNEX | sed 's/\//_/g')

for SRC in $SRCS; do
    if [[ ! -d "$SRC" ]]; then
        error "not a directory: $SRC"
    fi

    for DIR in $(find $SRC -name .git -prune -or -name $BACKUPS -or -type d -print); do
        # Caculate destiation path
        # TODO: Be smarter about removing year
        BASE=$(echo $DIR | sed -e 's/\//_/g' -e "s/$PREFIX_//" -e 's/_20[0-9][0-9]_/_/')
        DEST="${DEST_DIR}/${BASE}.tar.bz2"

        # Check for existing archive
        if [[ -e $DEST && ${FLAGS_overwrite} -eq ${FLAGS_FALSE} ]]; then
            STATUS='exists'
        else
            STATUS='ok'
        fi

        # Create archive
        if [[ $STATUS == 'ok' && ${FLAGS_simulate} -eq ${FLAGS_FALSE} ]]; then
            if [[ -h $DEST ]]; then
                git annex unlock $DEST && rm $DEST >&2
            fi

            if [[ $? -eq 0 ]]; then
                tar achvf $DEST --exclude='*.RAF' -C $DIR .
            fi

#                git annex add $DEST && \
#                git annex move $DEST --to glacier"

            if [[ $? -gt 0 ]]; then
                STATUS='error'
            fi
        fi

        log "$SRC -> $DEST [$STATUS]"
    done
done
