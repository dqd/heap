#!/usr/bin/python

import sys

SEPARATOR = '\n;'

if len(sys.argv) != 2:
    print "Usage: wikiaktuality.py <file.txt>"
    sys.exit(1)

f = open(sys.argv[1], 'r')
c = f.read()
f.close()

s = c.split(SEPARATOR)

while '' in s:
	s.remove('')

content = SEPARATOR[1] + SEPARATOR.join(s[::-1])

f = open(sys.argv[1], 'w')
f.write(content)
f.close()
