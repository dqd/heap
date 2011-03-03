#!/usr/bin/python

# Obtain the Megavideo codes for sharing

import re
import sys
from urllib2 import urlopen

if len(sys.argv) != 2:
    print "Usage: megavideo.py <file.txt>"
    sys.exit(1)

f = open(sys.argv[1], 'r')

for line in f.readlines():
    parts = line.split('\t', 1)
    url = parts[0].replace('upload', 'video')
    name = re.sub(r'.+\\(.+)$', r'\1', parts[1])
    html = urlopen(url).read()
    code = re.sub(re.compile(r'.+/v/(\w+).+', re.S), r'\1', html)

    output = '%s:' % name.strip()

    if '\n' in code:
        print '%s %s' % (output, "not processed yet.")
    else:
        print '%s\t%s' % (output, code)

f.close()
