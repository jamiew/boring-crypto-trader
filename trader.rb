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
  sleep 60
  order.cancel!

elsif action == 'stats'

  while true
    stats = MarketStats.new(client)
    orderbook = stats.orderbook_stats
    daily_stats = stats.daily_stats

    puts
    puts "----------- #{Time.now} -----------"
    puts "Spot Rate is $%.2f" % stats.spot_rate
    puts "Order book has #{orderbook[:bids]} open bids and #{orderbook[:asks]} open asks"
    puts "In the past hour, the maximum price movement was $%.2f" % stats.price_history.max
    puts "The highest price in in the past 24 hours was $%.2f" % daily_stats[:high]
    puts "The lowest price in in the past 24 hours was $%.2f" % daily_stats[:low]
    puts "You have #{stats.open_order_count} open orders."
    stats.print_order_stats
    puts "-------------------------------------------------"

    sleep 5
  end

elsif action.nil? || action.empty?

  $stderr.puts
  $stderr.puts "No action specified. Try 'buy' or 'run'. e.g.:"
  $stderr.puts
  $stderr.puts "    bundle exec ruby trader.rb run"
  $stderr.puts

else

  $stderr.puts "Don't understand #{action.inspect}"

end
