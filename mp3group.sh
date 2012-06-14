#!/bin/bash

if [ $# != 1 ]; then
    echo "Group mp3 files by the album and normalize them."
    echo "The directory structure is expected to be: dir/artist/album/*.mp3"
    echo "Usage: $0 <dir>"
    exit 1
fi

id3() {
    tag=`id3info "$1" | grep $2 | head -n 1`
    if [ -z "$tag" ]; then
        tag=`echo "$1" | cut -d/ -f$3`
    else
        tag=${tag#*:}
    fi
    echo $tag
}

find $1 -type d | while read dir; do
    count=`ls "$dir/"*.mp3 2> /dev/null | wc -l`

    if [ $count -gt 1 ]; then
        first=`ls "$dir/"*.mp3 | head -n 1`
        artist=`id3 "$first" TPE1 2`
        album=`id3 "$first" TALB 3`
        tmp="$1/tmp.mp3"
        cat "$dir/"*.mp3 > "$tmp"
        id3tag -s"$artist" -a"$album" "$tmp" > /dev/null
        normalize-mp3 --bitrate `mp3info -r m -p %r "$tmp"` "$tmp" &> /dev/null
        final="$1/$artist -- $album.mp3"
        mv "$tmp" "$final"
        echo "$final"
    fi
done
