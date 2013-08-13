#!/bin/bash

DEFAULT_SRC=/media
DEFAULT_DEST=~/workflow

# Source shflags (https://code.google.com/p/shflags/wiki/Documentation10x)
. shflags

# Configure shflags
DEFINE_boolean 'simulate' false 'simulate results without copying' 's'

# Parse flags & options
FLAGS_HELP="USAGE: $0 [flags] [source] [destination]"
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

if [ ${FLAGS_simulate} -eq ${FLAGS_TRUE} ]; then
    SIMULATE=true
else
    SIMULATE=false
fi

# Parse positional arguments
echo Parsing positional arguments... >&2
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
echo simulate = $SIMULATE >&2

SEQ=0
LASTBASE=
LASTDIR=

echo Processing files... >&2
for FILE in $(find $SRC -type f -regex '.*\(JPG\|RAF\)')
do
    # Get the file data
    EXIF=$(exiftool -EXIF:CreateDate -t -d '%y%m%d %H%M%S' $FILE | cut -f 2)
    BASE=$(basename $(basename $FILE .JPG) .RAF)
    echo $FILE -\> EXIF=$EXIF, BASE=$BASE >&2
    
    # Print "CREATE_DATE CREATE_TIME BASE FILE"
    echo "$EXIF $BASE $FILE"
done | sort | while read LINE
do
    # Parse the sorted line
    CREATE_DATE=$(echo $LINE | cut -d ' ' -f 1)
    BASE=$(echo $LINE | cut -d ' ' -f 3)
    SRC_PATH=$(echo $LINE | cut -d ' ' -f 4)

    # Create the destination directory
    DEST_DIR=$DEST/$CREATE_DATE
    if [ ! -d "$DEST_DIR" ]; then
        mkdir -pv $DEST_DIR
    fi

    # Reset the sequence # for each destination directory
    if [ "$DEST_DIR" != "$LASTDIR" ]; then
        SEQ=0
        LASTBASE=
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
    if [ ${FLAGS_simulate} -eq ${FLAGS_TRUE} ]; then
        echo cp -nv $SRC_PATH $DEST_PATH
    else
        #cp -nv $SRC_PATH $DEST_PATH
        echo oops
    fi
done

