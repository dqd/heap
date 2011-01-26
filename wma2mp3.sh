#!/bin/bash

for x in *.wma; do x=$(basename "$x" .wma); mplayer -ao pcm:file="$x.wav" "$x.wma"; lame -c -m j -q 0 --vbr-new -V 0 -b 192 -B 320 "$x.wav" "$x.mp3"; rm -f "$x.wav" "$x.wma"; done
