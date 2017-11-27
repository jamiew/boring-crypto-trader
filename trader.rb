require 'dotenv/load'
require 'coinbase/exchange'
require 'pp'

trading_pair = "ETH-USD"
@client = Coinbase::Exchange::Client.new(ENV['GDAX_API_KEY'], ENV['GDAX_API_SECRET'], ENV['GDAX_PASSPHRASE'], product_id: trading_pair)


def spot_rate
  @client.last_trade do |resp|
    p "Spot Rate: $%.2f" % resp.price
    pp resp
  end
end

def orderbook_stats
  @client.orderbook(level: 3)do |resp|
    p "There are #{resp.bids.count} open bids on the orderbook"
    p "There are #{resp.asks.count} open asks on the orderbook"
  end
end

def price_history
  @client.price_history(start: Time.now - 60*60, granularity: 60) do |resp|
    p "In the past hour, the maximum price movement was $%.2f" % resp.map { |candle| candle.high - candle.low }.max
  end
end

def daily_stats
  @client.daily_stats do |resp|
    p "The highest price in in the past 24 hours was $%.2f" % resp.high
    p "The lowest price in in the past 24 hours was $%.2f" % resp.low
  end
end

def open_order_count
  @client.orders(status: "open") do |resp|
    p "You have #{resp.count} open orders."
    pp resp
  end
end

# time_in_force options... https://support.gdax.com/customer/en/portal/articles/2426596-entering-market-limit-stop-orders
# GTC = Good Til Cancelled (default)
# IOC = Immediate Or Cancel
# FOK = Fill Or Kill
def execute_limit_order
  # args are [amount, price, *params]
  bid_amount = 0.01 # minimum size...
  current_price = spot_rate.price.to_f
  discount = 0.01
  bid_price = current_price - discount

  p "Initiating limit buy order for #{bid_amount} ETH @ $#{bid_price} ..."
  @client.bid(
    bid_amount,
    bid_price.round(2),
    type: "limit",
    time_in_force: "GTC",
    post_only: true # only act as a market maker (no fees)
  ) do |resp|
    p "Placed order for #{bid_amount} @ #{bid_price} Order ID is #{resp.id}"
  end
end


execute_limit_order

while true
  spot_rate
  orderbook_stats
  price_history
  daily_stats
  open_order_count

  exit 0

  # p "---------------"
  # sleep 10
end
