# coding: utf-8

import requests

from supybot.commands import *
import supybot.callbacks as callbacks


class ImagePig(callbacks.Plugin):
    def image(self, irc, msg, args, prompt):
        """<prompt>

        Generates an image.
        """
        api_key = self.registryValue("api_key")
        storage_days = self.registryValue("storage_days")

        try:
            r = requests.post(
                "https://api.imagepig.com/",
                headers={"Api-Key": api_key},
                json={"positive_prompt": prompt, "storage_days": storage_days},
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

    image = wrap(image, ["text"])


Class = ImagePig
