import supybot
import supybot.world as world

__version__ = "1.0"

__author__ = supybot.Author("Pavel Mises", "dqd", "id@dqd.cz")

__contributors__ = {}

__url__ = "https://github.com/dqd/heap/MegaHAL/"

import config
import plugin

reload(plugin)

if world.testing:
    import test

Class = plugin.Class
configure = config.configure
