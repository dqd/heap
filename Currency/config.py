import plugin

import supybot.conf as conf
import supybot.registry as registry

def configure(advanced):
    conf.registerPlugin('Currency', True)

Currency = conf.registerPlugin('Currency')

conf.registerGlobalValue(
    Currency,
    'api_key',
    registry.String(
        '',
        '''Sets the API key for the plugin. You can obtain an API key at https://www.alphavantage.co/.''',
        private=True
    )
)