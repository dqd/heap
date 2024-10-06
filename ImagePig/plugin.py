# coding: utf-8

import requests

from supybot.commands import *
import supybot.callbacks as callbacks


class ImagePig(callbacks.Plugin):
    def image(self, irc, msg, args, optlist, prompt):
        """[--model <model>] <prompt>

        Generates an image based on the prompt.
        """
        api_key = self.registryValue("api_key")
        storage_days = self.registryValue("storage_days")

        model = ""

        for option, arg in optlist:
            if option == "model":
                model = arg

        try:
            r = requests.post(
                "https://api.imagepig.com/{}".format(model),
                headers={"Api-Key": api_key},
                json={
                    "positive_prompt": prompt,
                    "storage_days": storage_days,
                },
            )

            if r.ok:
                url = r.json().get("image_url")
            else:
                r.raise_for_status()
        except Exception as e:
            irc.error(unicode(e), Raise=True)

        if url:
            irc.reply(url)
        else:
            irc.error("No image was returned for the prompt.")

    image = wrap(
        image, [getopts({"model": ("somethingWithoutSpaces", "model")}), "text"]
    )

    def faceswap(self, irc, msg, args, source, target):
        """<source_url> <target_url>

        Performs a faceswap using a face from <source_url> which replaces face in <target_url>.
        """
        api_key = self.registryValue("api_key")
        storage_days = self.registryValue("storage_days")

        try:
            r = requests.post(
                "https://api.imagepig.com/faceswap",
                headers={"Api-Key": api_key},
                json={
                    "source_image_url": source,
                    "target_image_url": target,
                    "storage_days": storage_days,
                },
            )

            if r.ok:
                url = r.json().get("image_url")
            else:
                r.raise_for_status()
        except Exception as e:
            irc.error(unicode(e), Raise=True)

        if url:
            irc.reply(url)
        else:
            irc.error("No image was returned for the faceswap.")

    faceswap = wrap(faceswap, ["somethingWithoutSpaces", "somethingWithoutSpaces"])


Class = ImagePig
