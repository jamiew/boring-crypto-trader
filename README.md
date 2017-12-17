boring-crypto-trader
--------------------

Use limit orders to do dollar cost averaging

Allows you to frequently buy small amounts of cryptos on Coinbase without fees (Bitcoin, Ethereum, Litecoin, etc)

Doesn't try to be be clever about timing, just buys on a regular schedule throughout the day

<img src="https://media.giphy.com/media/DG9o18mHjsa1G/giphy.gif" width="30%"> <img src="https://media.giphy.com/media/K5Yn9JCXcrXr2/giphy.gif" width="30%"> <img src="https://media.giphy.com/media/1WKmZA1CYSclG/giphy.gif" width="15%">



Setup
-----

You'll need recent-ish versions of ruby and bundler

```
bundle install
```

Register a [GDAX API key](https://www.gdax.com/settings/api) -- just need View & Trade permissions

Then copy `.env.sample` to `.env` and put in your API keys


Running
-------

```
TEST=1 bundle exec ruby trader.rb buy 0.01 ETH
```

You can specify how much you want to pay instead:

```
TEST=1 bundle exec ruby trader.rb buy 25USD ETH
```

Remove TEST=1 to buy things for real

Good luck



License
-------

Released to the public under an [MIT License](https://opensource.org/licenses/MIT)