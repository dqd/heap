# coding: utf-8

import requests

from supybot.commands import *
import supybot.callbacks as callbacks

try:
    from alpha_vantage.foreignexchange import ForeignExchange
except ImportError:
    ALPHA_VANTAGE = False
else:
    ALPHA_VANTAGE = True


class Currency(callbacks.Plugin):
    SYMBOLS = {
        '€': 'EUR',
        '$': 'USD',
        '¥': 'JPY',
        '£': 'GBP',
    }
    AVAILABLE_CURRENCIES = (
        'AUD',
        'BGN',
        'BRL',
        'CAD',
        'CHF',
        'CNY',
        'CZK',
        'DKK',
        'EUR',
        'GBP',
        'HKD',
        'HRK',
        'HUF',
        'IDR',
        'ILS',
        'INR',
        'ISK',
        'JPY',
        'KRW',
        'MXN',
        'MYR',
        'NOK',
        'NZD',
        'PLN',
        'RON',
        'RUB',
        'SEK',
        'SGD',
        'THB',
        'TRY',
        'USD',
        'ZAR',
    )

    @staticmethod
    def _normalize(c):
        if c in Currency.SYMBOLS:
            return Currency.SYMBOLS[c]

        return c[:3].upper()

    def currency(self, irc, msg, args, amount, c1, c2):
        '''[<amount>] <currency1> to <currency2>

        Converts from <currency1> to <currency2>. If amount is not given,
        it defaults to 1.
        '''
        api_key = self.registryValue('api_key')

        c1 = self._normalize(c1)
        c2 = self._normalize(c2)

        rate = None

        try:
            if ALPHA_VANTAGE and api_key and \
                (c1 not in Currency.AVAILABLE_CURRENCIES or
                 c2 not in Currency.AVAILABLE_CURRENCIES):
                fe = ForeignExchange(key=api_key)
                r, _ = fe.get_currency_exchange_rate(
                    from_currency=c1,
                    to_currency=c2,
                )
                rate = float(r.get('5. Exchange Rate', 0))
            else:
                r = requests.get(
                    'http://api.fixer.io/latest?base={}'.format(c1)
                )

                if r.ok:
                    rate = r.json().get('rates', {}).get(c2)
        except Exception as e:
            irc.error(unicode(e), Raise=True)

        if rate:
            irc.reply('{:.2f} {} = {:.2f} {}'.format(amount, c1, amount * rate, c2))
        else:
            irc.error('Unable to convert {} to {}.'.format(c1, c2))

    currency = wrap(currency, [optional('float', 1.0), 'something', 'to', 'something'])

Class = Currency