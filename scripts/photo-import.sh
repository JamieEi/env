#!/bin/bash

DEFAULT_SRC=/media
DEFAULT_DEST=~/photos

# Make sure exiftool is installed in path
if [ ! $(which exiftool) ]; then
    echo "Requires exiftool, see http://www.sno.phy.queensu.ca/~phil/exiftool/install.html#Unix" >&2
    exit 1
fi

# Source shflags (https://code.google.com/p/shflags/wiki/Documentation10x)
. shflags

# Configure shflags
DEFINE_boolean 'simulate' false 'simulate results without copying' 's'

# Parse flags & options
FLAGS_HELP="USAGE: $0 [flags] [source] [destination]"
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

# Evals or simulates a string based on the --simulate flag
function evalOrSimulate {
    if [ ${FLAGS_simulate} -eq ${FLAGS_TRUE} ]; then
        echo $1 >&2
    else
        eval $1 >&2
    fi
}

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

SEQ=0
LASTBASE=
LASTDIR=
declare -A HASHES

N_FILES=0
N_COPIED=0

echo -e "\nProcessing files..." >&2
for FILE in $(find $SRC -type f -regex '.*\(JPG\|RAF\)')
do
    N_FILES=$((N_FILES+1))

    # Get the file data
    EXIF=$(exiftool -EXIF:CreateDate -t -d '%y%m%d %H%M%S' $FILE | cut -f 2)
    BASE=$(basename $(basename $FILE .JPG) .RAF)

    # Validate
    VALID=true
    STATUS="ok"

    if [[ $(echo $EXIF | wc -w) -ne 2 ]]; then
        VALID=false
        STATUS="missing EXIF data"
    fi

    if [[ $VALID && $(echo $BASE | wc -w) -ne 1 ]]; then
        VALID=false
        STATUS="error extracting BASE"
    fi
    
    # Check for duplicates
    HASH=$(sha1sum $FILE | cut -f 1 -d ' ')
    if [[ $VALID && ${HASHES[$HASH]} ]]; then
        VALID=false
        STATUS="duplicate"
    fi

    # Save the hash
    if [[ $VALID ]]; then
        declare -A HASHES=( [$HASH]=$FILE )
    fi

    # Print file data to pipe. Note that EXIF has multiple fields.
    echo "$N_FILES $EXIF $BASE $FILE $VALID"

    # Log progress
    echo "$FILE -> $STATUS" >&2
done | sort | while read LINE
do
    # Parse the sorted line
    N_FILES=$(echo $LINE | cut -d ' ' -f 1)
    CREATE_DATE=$(echo $LINE | cut -d ' ' -f 2)
    BASE=$(echo $LINE | cut -d ' ' -f 4)
    SRC_PATH=$(echo $LINE | cut -d ' ' -f 5)
    VALID=$(echo $LINE | cut -d ' ' -f 6)

    if [[ $N_FILES == "1" ]]; then
        echo -e "\nCopying files..." >&2
    fi

    if [[ $VALID  == "true" ]]; then
        # Reset the sequence # for each destination directory
        DEST_DIR=$DEST/$CREATE_DATE
        if [ "$DEST_DIR" != "$LASTDIR" ]; then
            # Reset the sequence #
            SEQ=0
            LASTBASE=

            # Process or create the destination directory
            if [ -d "$DEST_DIR" ]; then
                FOO=1
                # TODO: Set SEQ to max value
                # TODO: Add file hashes
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
        SRC_FILE=$(basename $SRC_PATH)
        EXT=${SRC_FILE##$BASE}
        DEST_PATH=$DEST_DIR/${CREATE_DATE}_$(printf '%04d' $SEQ)$EXT

        # Copy the file
        evalOrSimulate "cp -nv $SRC_PATH $DEST_PATH"
        N_COPIED=$((N_COPIED+1))
    fi

    # Print stats to escape them from the pipe subshell
    echo -e "\nStatistics..."
    echo "# files = $N_FILES"
    echo "# copied = $N_COPIED"
    echo "# skipped = $((N_FILES-N_COPIED))"
done | tail -n 5 >&2


