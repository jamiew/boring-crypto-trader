require 'dotenv/load'
require 'coinbase/exchange'
require 'pp'

trading_pair = "ETH-USD"
client = Coinbase::Exchange::Client.new(ENV['GDAX_API_KEY'], ENV['GDAX_API_SECRET'], ENV['GDAX_PASSPHRASE'], product_id: trading_pair)

while true
  # pp client.last_trade

  client.last_trade do |resp|
    p "Spot Rate: $%.2f" % resp.price
  end

  client.orderbook(level: 3)do |resp|
    p "There are #{resp.bids.count} open bids on the orderbook"
    p "There are #{resp.asks.count} open asks on the orderbook"
  end

  client.price_history(start: Time.now - 60*60, granularity: 60) do |resp|
    p "In the past hour, the maximum price movement was $%.2f" % resp.map { |candle| candle.high - candle.low }.max
  end

  client.daily_stats do |resp|
    p "The highest price in in the past 24 hours was $%.2f" % resp.high
    p "The lowest price in in the past 24 hours was $%.2f" % resp.low
  end

  client.orders(status: "open") do |resp|
    p "You have #{resp.count} open orders."
  end

  p "---------------"
  sleep 10
end
