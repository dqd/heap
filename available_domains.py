#!/usr/bin/python

from DNS import Base
from time import sleep
from subprocess import Popen, PIPE

TLD = 'cz'
LENGTH = 3
FAST = True
LETTERS = map(chr, range(ord('a'), ord('z') + 1)) + map(str, range(10))

if Base.defaults['server'] == []:
    Base.DiscoverNameServers()

def check_domain(domain):
    try:
        if not Base.DnsRequest(domain, qtype='ns').req().answers:
            raise Base.DNSError
    except Base.DNSError:
        if not FAST:
            sleep(30)
            if 'No entries found.' in Popen(['whois', domain], stdout=PIPE).communicate()[0]:
                print domain
        else:
            print domain

def generate_name(name, depth):
    for letter in LETTERS:        
        if depth > 1:
            generate_name(name + letter, depth - 1)
        else:
            check_domain('%s%s.%s' % (name, letter, TLD))

generate_name('', LENGTH)
