import plugin

import supybot.conf as conf
import supybot.registry as registry

def configure(advanced):
    conf.registerPlugin('Weather', True)

Weather = conf.registerPlugin('Weather')

conf.registerGlobalValue(
    Weather,
    'api_key',
    registry.String(
        '',
        '''Sets the API key for the plugin. You can obtain an API key at https://www.apixu.com/.''',
        private=True
    )
)