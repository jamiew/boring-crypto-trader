boring-crypto-trader
--------------------

Use limit orders to buy without fees on Coinbase/GDAX. Handy for

This script makes it easier to frequently buy small amounts of cryptos without fees (Bitcoin, Ethereum, Litecoin, etc)

Good for [dollar cost averaging](https://www.bogleheads.org/wiki/Dollar_cost_averaging) your purchases.
Doesn't try to be be clever about timing, just buys on a regular schedule throughout the day.

<img src="https://media.giphy.com/media/DG9o18mHjsa1G/giphy.gif" width="30%"> <img src="https://media.giphy.com/media/K5Yn9JCXcrXr2/giphy.gif" width="30%"> <img src="https://media.giphy.com/media/1WKmZA1CYSclG/giphy.gif" width="15%">



Setup
-----

You'll need recent-ish versions of ruby and bundler

```
bundle install
```

Register a [GDAX API key](https://www.gdax.com/settings/api) -- justs need View & Trade permissions

Then copy `.env.sample` to `.env` and put in your API keys


Running
-------

To buy exactly 0.01 ether:

```
TEST=1 bundle exec ruby trader.rb buy 0.01 ETH
```

To buy $5 worth of bitcoin:

```
TEST=1 bundle exec ruby trader.rb buy 25USD BTC
```

(using "$5" is clumsy because it's a shell variable, but "\$5" also works)

Remove TEST=1 to buy things for real

Please note that test mode just submits a very low bid (-$100) instead of the usual -$0.01.
That means there's a non-zero it might really result in you buying something.

Good luck



License
-------

We obviously take zero liabilities for your trading activity when using this software.

This source code released to the public under an [MIT License](https://opensource.org/licenses/MIT)

Issues and pull requests are welcome