# coding: utf-8

from datetime import datetime

from supybot.commands import *
import supybot.callbacks as callbacks

from apixu.client import ApixuClient


class Weather(callbacks.Plugin):
    PLACES = {
        'praha': 'Prague',
        'pilsen': 'Plzen',
    }

    def weather(self, irc, msg, args, place):
        '''<place>

        Current weather for a <place>.
        '''
        api_key = self.registryValue('api_key')

        if not api_key:
            irc.error(
                'The API key is missing. '
                'Please configure the plugins.Weather.api_key directive.',
                Raise=True,
            )

        place = place.lower()

        if place in Weather.PLACES:
            place = Weather.PLACES[place]

        try:
            client = ApixuClient(api_key)
            response = client.current(q=place)
            last_updated = datetime.fromtimestamp(
                response['current']['last_updated_epoch'],
            ).strftime('%Y-%m-%d %H:%M')
            irc.reply(
                'The current temperature in {l[name]}, '
                '{l[country]} is {w[temp_c]} °C '
                '(feels like {w[feelslike_c]} °C). '
                'Conditions: {w[condition][text]}. '
                'Humidity: {w[humidity]} %. '
                'Wind: {w[wind_dir]} {w[wind_kph]} km/h ({d}).'.format(
                    w=response['current'],
                    l=response['location'],
                    d=last_updated,
                )
            )
        except Exception as e:
            irc.error(unicode(e))

    weather = wrap(weather, ['text'])

Class = Weather