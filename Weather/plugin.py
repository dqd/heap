# coding: utf-8

from datetime import datetime

import requests
from supybot.commands import *
import supybot.callbacks as callbacks


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

            params = {
                'access_key': api_key,
                'query': place,
            }
            response = requests.get('http://api.weatherstack.com/current', params=params).json()
            irc.reply(
                'The current temperature in {l[name]}, '
                '{l[country]} is {w[temperature]} °C '
                '(feels like {w[feelslike]} °C). '
                'Conditions: {w[weather_descriptions][0]}. '
                'Humidity: {w[humidity]} %. '
                'Wind: {w[wind_dir]} {w[wind_speed]} km/h ({l[localtime]}).'.format(
                    w=response['current'],
                    l=response['location'],
                )
            )
        except Exception as e:
            irc.error(u'{}: {}'.format(type(e).__name__, unicode(e)))

    weather = wrap(weather, ['text'])

Class = Weather
