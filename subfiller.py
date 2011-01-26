#! /usr/bin/python

import sys
from pysrt import SubRipFile

if len(sys.argv) != 2:
    print "Usage: subfiller <file.srt>"
    sys.exit(1)

srt = SubRipFile.open(sys.argv[1], 'cp1250')

letter = 'A'

for s in srt:
    title_len = len(s.text.strip())

    if title_len == 0:
        s.text = letter + '\n'

        if letter == 'Z':
            letter = 'A'
        else:
            letter = chr(ord(letter) + 1)
    elif title_len == 1 and s.text[0].isupper():
        letter = chr(ord(s.text[0]) + 1)

srt.save(eol='\r\n')
