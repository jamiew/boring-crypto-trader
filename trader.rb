#!/usr/bin/env ruby

require 'dotenv/load'
require 'coinbase/exchange'
require 'pp'

require_relative 'limit_order'
require_relative 'market_stats'

TRADING_PAIR = "ETH-USD"

# TODO throw error if missing required ENV variables
client = Coinbase::Exchange::Client.new(
    ENV['GDAX_API_KEY'], ENV['GDAX_API_SECRET'], ENV['GDAX_PASSPHRASE'],
    product_id: TRADING_PAIR
  )

action = ARGV[0].to_s

if action == 'buy'

  order = LimitOrder.new(client)
  order.buy!
  puts "Status: #{order.status.inspect}"
  puts "Waiting, then cancelling..."
  sleep 60
  order.cancel!

elsif action == 'cancel'

  orders = client.orders(status: "open")
  orders.each do |order|
    puts "Cancelling #{order.id}..."
    canceller = LimitOrder.new(client)
    canceller.order_id = order.id
    canceller.cancel!
  end
  puts "Done"

elsif action == 'stats'

  while true
    stats = MarketStats.new(client)
    orderbook = stats.orderbook_stats
    daily_stats = stats.daily_stats

    puts
    puts "----------- #{Time.now} -----------"
    puts "Spot Rate is $%.2f" % stats.spot_rate
    # TODO calculate some basic price movement statistics
    # 1m mavd
    puts "Order book has #{orderbook[:bids]} open bids and #{orderbook[:asks]} open asks"
    puts "In the past hour, the maximum price movement was $%.2f" % stats.price_history.max
    puts "The highest price in in the past 24 hours was $%.2f" % daily_stats[:high]
    puts "The lowest price in in the past 24 hours was $%.2f" % daily_stats[:low]
    puts "You have #{stats.open_order_count} open orders."
    stats.print_order_stats
    puts "-------------------------------------------------"

    sleep 5
  end

else

  $stderr.puts ""
  $stderr.puts "No action specified. Try: run, buy, cancel"
  $stderr.puts " e.g."
  $stderr.puts "    bundle exec ruby trader.rb run"
  $stderr.puts ""

end
