# coding: utf-8

import os
from cPickle import UnpicklingError

from megahal import MegaHAL, DEFAULT_BRAINFILE
from supybot.commands import *
import supybot.callbacks as callbacks
import supybot.conf as conf

training_data = conf.supybot.directories.data.dirize("megahal")

megahal = None

try:
    if os.path.exists(DEFAULT_BRAINFILE):
        megahal = MegaHAL()
except UnpicklingError:
    pass

if megahal is None:
    if os.path.exists(DEFAULT_BRAINFILE):
        os.remove(DEFAULT_BRAINFILE)

    if not os.path.exists(training_data):
        with open(training_data, "w") as f:
            f.write("")

    megahal = MegaHAL()
    megahal.train(training_data)  # this can take a while
    megahal.sync()


class MegaHAL(callbacks.Plugin):
    def chat(self, irc, msg, args, text):
        """<text>

        Replies to a message.
        """
        with open(training_data, "a") as f:
            f.write(text)
            f.write("\n")

        irc.reply(megahal.get_reply(text))

    chat = wrap(chat, ["text"])

    def die(self):
        megahal.sync()


Class = MegaHAL
