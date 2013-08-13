#!/bin/bash

SRC=Pictures/staging/130623 #~/Pictures/shower

SEQ=0
LASTBASE=

for FILE in $(find $SRC -type f -regex '.*\(JPG\|RAF\)')
do
    # Get the file data
    EXIF=$(exiftool -EXIF:CreateDate -t -d '%y%m%d %H%M%S' $FILE | cut -f 2)
    BASE=$(basename $(basename $FILE .JPG) .RAF)
    
    # Print "CREATE_DATE CREATE_TIME BASE FILE"
    echo "$EXIF $BASE $FILE"
done | sort | while read LINE
do
    # Parse the sorted line
    CREATE_DATE=$(echo $LINE | cut -d ' ' -f 1)
    BASE=$(echo $LINE | cut -d ' ' -f 3)
    SRC=$(echo $LINE | cut -d ' ' -f 4)

    # Create the destination directory
    DIR=~/workflow/$CREATE_DATE
    if [ ! -d "$DIR" ]; then
        mkdir -pv $DIR
    fi

    # Increment the sequence number
    if [ "$BASE" != "$LASTBASE" ]; then
        SEQ=$((SEQ+1))
        LASTBASE=$BASE
    fi

    # Compute the destination path
    FILE=$(basename $SRC)
    EXT=${FILE##$BASE}
    DEST=$DIR/${CREATE_DATE}_$(printf '%04d' $SEQ)$EXT

    # Copy the file
    echo "cp -v $SRC $DEST"
done
