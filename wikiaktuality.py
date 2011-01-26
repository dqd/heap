#!/usr/bin/python

import sys

SEPARATOR = '\n;'

if len(sys.argv) != 2:
    print "Usage: wikiaktuality.py <file.txt>"
    sys.exit(1)

f = open(sys.argv[1], 'r')
c = f.read()
f.close()

s1 = c.split(SEPARATOR)
s2 = s1[-1].split(SEPARATOR[0] * 2, 2)

content = SEPARATOR[1] + s2[0] + SEPARATOR + SEPARATOR.join(s1[:-1][::-1]) + SEPARATOR[0] * 2 + s2[1]

f = open(sys.argv[1], 'w')
f.write(content)
f.close()
