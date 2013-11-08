#!/usr/bin/zsh --sh-word-split

DEFAULT_SRC=/media
DEFAULT_DEST=~/photos
# TODO: Stop repeating pattern
# TODO: Make extensions an option
EXT_PATTERN="JPG|RAF|jpg|raf"

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
# Requirements
####################################################################################################

if [ ! $(which exiftool) ]; then
    error "requires exiftool, see http://www.sno.phy.queensu.ca/~phil/exiftool/install.html#Unix"
fi

####################################################################################################
# Argument parsing
####################################################################################################

# Source shflags (https://code.google.com/p/shflags/wiki/Documentation10x)
FLAGS_PARENT=$0
. shflags

# Configure shflags
# TODO: debug flag: more detail, implies simulate
DEFINE_boolean 'simulate' false 'simulate results without copying' 's'

# Parse flags & options
FLAGS_HELP="USAGE: $0 [flags] [source] [destination]"
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

# Parse positional arguments
if [ $# -eq 0 ]; then
    SRC=$DEFAULT_SRC
    DEST=$DEFAULT_DEST
elif [ $# -eq 1 ]; then
    SRC=$1
    DEST=$DEFAULT_DEST
elif [ $# -eq 2 ]; then
    SRC=$1
    DEST=$2
else
    log "error: too many arguments ($#)"
    flags_help
    exit 1
fi

logKeyValue "source" $SRC
logKeyValue "destination" $DEST

if [[ ! -d "$SRC" ]]; then
    error "source does not exist"
fi

####################################################################################################
# Get file data
####################################################################################################

# Get the file list
FILES=($SRC/**/*.(JPG|RAF|jpg|raf))
logSectionTitle "analyzing $#FILES source files"

# Declare associative arrays
declare -A FILE_CREATE_DATE
declare -A FILE_CREATE_TIME
declare -A FILE_BASES
declare -A FILE_EXTS
declare -A FILE_DEST_DIRS
declare -A SORT_KEY_FILES
declare -A SORT_KEY_HASHES
declare -A DEST_DIRS

# Get file data
for FILE in $FILES
do
    EXIF=$(exiftool -EXIF:CreateDate -t -d '%y%m%d %H%M%S' $FILE | cut -f 2)
    CREATE_DATE=$(echo $EXIF | cut -d ' ' -f 1)
    CREATE_TIME=$(echo $EXIF | cut -d ' ' -f 2)
    FILENAME=$(basename $FILE)
    BASE=${FILENAME%%.(JPG|RAF|jpg|raf)}
    EXT=${FILENAME##$BASE.}
    SORT_KEY="$CREATE_DATE:$CREATE_TIME:$BASE:$EXT"
    HASH=$(sha1sum $FILE | cut -f 1 -d ' ')
    DEST_DIR=$DEST/$CREATE_DATE

    FILE_CREATE_DATE[$FILE]=$CREATE_DATE
    FILE_CREATE_TIME[$FILE]=$CREATE_TIME
    FILE_BASES[$FILE]=$BASE
    FILE_EXTS[$FILE]=$EXT
    FILE_DEST_DIRS[$FILE]=$DEST_DIR
    SORT_KEY_FILES[$SORT_KEY]=$FILE
    SORT_KEY_HASHES[$SORT_KEY]=$HASH
    DEST_DIRS[$DEST_DIR]=true
    logKeyValue $FILE "SORT_KEY=$SORT_KEY, DEST_DIR=$DEST_DIR"
done

####################################################################################################
# Process dest file contents
####################################################################################################

logSectionTitle "scanning $#DEST_DIRS destination directories"

declare -A DEST_FILE_HASHES
declare -A DEST_DIR_MAXSEQ

for DEST_DIR in ${(k)DEST_DIRS}
do
    if [[ -d "$DEST_DIR" ]]; then
        DEST_FILES=($DEST_DIR/*.(JPG|RAF|jpg|raf))
        MAXSEQ=0

        for FILE in $DEST_FILES
        do
            HASH=$(sha1sum $FILE | cut -f 1 -d ' ')
            DEST_FILE_HASHES[$HASH]=$FILE

            FILENAME=$(basename $FILE)

            # Get the sequence number from a filename like 130825_0001.JPG
            SEQSTR=${${FILENAME##*_}%%.(JPG|RAF|jpg|raf)}
            SEQ=`expr 0 + $SEQSTR`

            if [[ $SEQ -gt $MAXSEQ ]]; then
                MAXSEQ=$SEQ
            fi
        done

        DEST_DIR_MAXSEQ[$DEST_DIR]=$MAXSEQ
        logKeyValue $DEST_DIR "$#DEST_FILES files, max seq = $MAXSEQ"
    else
        logKeyValue $DEST_DIR "does not exist"
    fi
done

echo "# hashes = $#DEST_FILE_HASHES"

####################################################################################################
# Copy files
####################################################################################################

logSectionTitle "copying files"

# Sort the sort keys. For some reason doing this w/ ${ko@)SORT_KEY_HASHES} doesn't work.
declare -a SORT_KEYS
SORT_KEYS=( $(for k in ${(k)SORT_KEY_HASHES}; do echo $k; done | sort) )

# Iterate over the sort keys / files
N_COPIED=0
for SORT_KEY in $SORT_KEYS
do
    log "SORT_KEY=$SORT_KEY"

    HASH=$SORT_KEY_HASHES[$SORT_KEY]
    FILE=$SORT_KEY_FILES[$SORT_KEY]
    DEST_DIR=$FILE_DEST_DIRS[$FILE]
    CREATE_DATE=$FILE_CREATE_DATE[$FILE]
    BASE=$FILE_BASES[$FILE]
    EXT=$FILE_EXTS[$FILE]

    # Validate
    if [[ ! "$SORT_KEY" =~ "^[0-9]{6}-[0-9]{6}-[A-Za-z0-9]+" ]]; then
        STATUS="invalid sort key ($SORT_KEY)"
    elif [[ -n $DEST_FILE_HASHES[$HASH] ]]; then
        STATUS="duplicate"
    else
        STATUS="ok"
    fi

    # If everthing is ok process the file
    if [[ $STATUS == "ok" ]]; then
        # Handle new directories
        if [ "$DEST_DIR" != "$LASTDIR" ]; then
            # Reset the sequence #
            SEQ=${DEST_DIR_MAXSEQ[$DEST_DIR]:-0}
            LASTBASE=

            # Create the destination directory
            if [ ! -d "$DEST_DIR" ]; then
                evalOrSimulate "mkdir -pv $DEST_DIR"
            fi
        fi
        LASTDIR=$DEST_DIR

        # Increment the sequence number
        if [ "$BASE" != "$LASTBASE" ]; then
            SEQ=$((SEQ+1))
            LASTBASE=$BASE
        fi

        # Compute the destination path
        FILENAME=$(basename $FILE)
        DEST_PATH="$DEST_DIR/${CREATE_DATE}_$(printf '%04d' $SEQ).$EXT"

        # Copy the file
        evalOrSimulate "cp -nv $FILE $DEST_PATH"
        N_COPIED=$((N_COPIED+1))
    else
        logKeyValue $FILE $STATUS
    fi
done

# Print stats
logSectionTitle "statistics"
N_FILES=$#SORT_KEY_FILES
logKeyValue "# files" $N_FILES
logKeyValue "# copied" $N_COPIED
logKeyValue "# skipped" $((N_FILES-N_COPIED))
