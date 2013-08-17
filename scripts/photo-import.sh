#!/usr/bin/zsh --sh-word-split

####################################################################################################
# Helper functions
####################################################################################################

# Evals or simulates a string based on the --simulate flag
function evalOrSimulate {
    if [ ${FLAGS_simulate} -eq ${FLAGS_TRUE} ]; then
        echo $1 >&2
    else
        eval $1 >&2
    fi
}

function error {
    echo "error: $1" >&2
    exit 1
}

declare -A DEST_FILE_HASHES

function addHash {
    HASH=$(sha1sum $1 | cut -f 1 -d ' ')
    DEST_FILE_HASHES[$HASH]=$FILE
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

DEFAULT_SRC=/media
DEFAULT_DEST=~/photos

# Source shflags (https://code.google.com/p/shflags/wiki/Documentation10x)
FLAGS_PARENT=$0
. shflags

# Configure shflags
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
    echo "error: too many arguments ($#)" >&2
    flags_help
    exit 1
fi

echo source = $SRC >&2
echo destination = $DEST >&2

if [[ ! -d "$SRC" ]]; then
    error "source does not exist"
fi

####################################################################################################
# Get file data
####################################################################################################

# Get the file list
FILES=($SRC/*.(JPG|RAF))
echo "found $#FILES files" >&2

# Declare associative arrays
declare -A FILE_CREATE_DATE
declare -A FILE_CREATE_TIME
declare -A FILE_BASES
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
    BASE=$(basename $(basename $FILE .JPG) .RAF)
    SORT_KEY="$CREATE_DATE-$CREATE_TIME-$BASE"
    HASH=$(sha1sum $FILE | cut -f 1 -d ' ')
    DEST_DIR=$DEST/$CREATE_DATE

    FILE_CREATE_DATE[$FILE]=$CREATE_DATE
    FILE_CREATE_TIME[$FILE]=$CREATE_TIME
    FILE_BASES[$FILE]=$BASE
    FILE_DEST_DIRS[$FILE]=$DEST_DIR
    SORT_KEY_FILES[$SORT_KEY]=$FILE
    SORT_KEY_HASHES[$SORT_KEY]=$HASH
    DEST_DIRS[$DEST_DIR]=true
done

####################################################################################################
# Process dest file contents
####################################################################################################

echo -e "\nscanning $#DEST_DIRS destination directories..." >&2

# TODO: Set starting SEQ

for DEST_DIR in ${(k)DEST_DIRS}
do
    DEST_FILES=($DEST_DIR/*.(JPG|RAF))
    for FILE in $DEST_FILES
    do
        addHash $FILE
    done
    echo "$DEST_DIR: $#DEST_FILES files" >&2
done

echo "# hashes = $#DEST_FILE_HASHES"

####################################################################################################
# Copy files
####################################################################################################

echo -e "\ncopying files..." >&2

SEQ=0
LASTBASE=
LASTDIR=
N_COPIED=0

# Sort the sort keys
SORT_KEYS_ASC=${(ko@)SORT_KEY_HASHES}

# Iterate over the sort keys / files
for SORT_KEY in $SORT_KEYS_ASC
do
    HASH=$SORT_KEY_HASHES[$SORT_KEY]
    FILE=$SORT_KEY_FILES[$SORT_KEY]
    DEST_DIR=$FILE_DEST_DIRS[$FILE]
    CREATE_DATE=$FILE_CREATE_DATE[$FILE]
    BASE=$FILE_BASES[$FILE]

    # Validate
    if [[ $SORT_KEY == "xxx" ]]; then
        STATUS="invalid sort key ($SORT_KEY)"
    elif [[ -n $DEST_FILE_HASHES[$HASH] ]]; then
        STATUS="duplicate"
    else
        STATUS="ok"
    fi

    # If everthing is ok process the file
    if [[ $STATUS == "ok" ]]; then
        # Reset the sequence # for each destination directory
        if [ "$DEST_DIR" != "$LASTDIR" ]; then
            # Reset the sequence #
            SEQ=0
            LASTBASE=

            # Process or create the destination directory
            if [ -d "$DEST_DIR" ]; then
                FOO=1
                # TODO: Set SEQ to max value
            else
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
        EXT=${FILENAME##$BASE}
        DEST_PATH=$DEST_DIR/${CREATE_DATE}_$(printf '%04d' $SEQ)$EXT

        # Copy the file
        evalOrSimulate "cp -nv $FILE $DEST_PATH"
        N_COPIED=$((N_COPIED+1))
    else
        echo "$FILE -> $STATUS" >&2
    fi
done | tail -n 5 >&2

# Print stats to escape them from the pipe subshell
echo -e "\nstatistics..."
N_FILES=$#SORT_KEY_FILES
echo "# files = $N_FILES"
echo "# copied = $N_COPIED"
echo "# skipped = $((N_FILES-N_COPIED))"

