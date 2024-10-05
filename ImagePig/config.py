import plugin

import supybot.conf as conf
import supybot.registry as registry


def configure(advanced):
    conf.registerPlugin("ImagePig", True)


ImagePig = conf.registerPlugin("ImagePig")

conf.registerGlobalValue(
    ImagePig,
    "api_key",
    registry.String(
        "",
        """Sets the API key for the plugin. You can obtain an API key at https://imagepig.com/.""",
        private=True,
    ),
)

conf.registerGlobalValue(
    ImagePig,
    "storage_days",
    registry.Integer(
        30,
        """Sets how many days the generated images should be retained.""",
        private=False,
    ),
)
