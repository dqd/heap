import plugin

import supybot.conf as conf

def configure(advanced):
    conf.registerPlugin('Currency', True)

Currency = conf.registerPlugin('Currency')