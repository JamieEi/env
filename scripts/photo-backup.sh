#!/usr/bin/zsh --sh-word-split

DEST_DIR=~/photos/backup

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

# Parse flags & options
FLAGS_HELP="USAGE: $0 [flags] [dirs]"
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

####################################################################################################
# Get file data
####################################################################################################

for SRC in "$@"; do
    echo $SRC >&2
    if [[ ! -d "$SRC" ]]; then
        error "not a directory: $SRC"
    fi

    ABS=$(/bin/readlink -e "$SRC")
    BASE=$(/usr/bin/basename $ABS)
    PREFIX=$(/usr/bin/basename $(/usr/bin/dirname $ABS))

    if [[ -z "$BASE" ]]; then
        error "missing base: $SRC"
    fi

    if [[ -z "$PREFIX" ]]; then
        error "missing prefix: $SRC"
    fi

    DEST=$DEST_DIR/$PREFIX_$BASE.tar.bz2
    echo tar -cjvf $DEST $SRC >&2
done
