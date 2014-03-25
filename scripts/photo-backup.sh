#!/usr/bin/zsh --sh-word-split

DEST_DIR=~/annex/backups

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
DEFINE_boolean 'simulate' false 'simulate results without archiving' 's'

# Parse flags & options
FLAGS_HELP="USAGE: $0 [flags] [dirs]"
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

# Require at least 1 directory
if [[ $# < 1 ]]; then
    flags_help
    exit 1
fi

####################################################################################################
# Backup
####################################################################################################

for SRC in "$@"; do
    echo $SRC >&2
    if [[ ! -d "$SRC" ]]; then
        error "not a directory: $SRC"
    fi

    # Extract parts from path
    PARTS=( $(readlink -e "$SRC" | sed 's/\// /g') )
    MEDIA_TYPE=photos
    SUBTYPE=$PARTS[-3]
    DATE=$PARTS[-1]

    if [[ -z "$MEDIA_TYPE" ]]; then
        error "missing media type: $SRC"
    fi

    if [[ -z "$SUBTYPE" ]]; then
        error "missing subtype: $SRC"
    fi

    if [[ -z "$DATE" ]]; then
        error "missing date: $SRC"
    fi

    DEST="${DEST_DIR}/${MEDIA_TYPE}_${SUBTYPE}_${DATE}.tar.bz2"

    evalOrSimulate "tar chvf $DEST $SRC"
done
