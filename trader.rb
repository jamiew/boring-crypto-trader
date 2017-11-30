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

  # Try buying for ~10 minutes before giving up
  start_time = Time.now
  max_attempts = 200
  sleep_time = 2
  puts "Going to try buying #{max_attempts} times..."
  (0..max_attempts).each do |i|
    current_price = order.current_price.to_f
    paid_price = order.order_bid_price.to_f
    drift = current_price - paid_price
    puts "##{i}: Spot rate is $#{current_price.to_f}   Bid is #{paid_price.to_f}   Drift is #{drift.round(2)} (#{(100 - drift/order.bid_difference*100.0).round(1)}%)    Status=#{order.status}"

    # If our bid has drifted too far from current price, cancel it and re-bid
    if drift.abs > order.bid_difference * 1.1
      puts "Too much drift, cancelling and re-bidding"
      order.cancel!
      order.buy!
    end

    if order.status == 'done'
      puts "Order filled! Nice job!"
      exit 0
    elsif order.status == 'open'
      # Just continue
    else
      $stderr.puts "Unknown order status '#{order.status}, halting"
      order.cancel!
      exit 1
    end

    sleep sleep_time
  end

  order.cancel!
  exit 1

elsif action == 'cancel'

  orders = client.orders(status: "open")
  puts "Cancelling #{orders.length} orders..."
  orders.each do |order|
    puts "Cancelling #{order.id}..."
    canceller = LimitOrder.new(client)
    canceller.order_id = order.id
    canceller.cancel!
  end
  puts "Done"
  exit 0

elsif action == 'run'

  while true
    stats = MarketStats.new(client)
    orderbook = stats.orderbook_stats
    daily_stats = stats.daily_stats

    puts
    puts "----------- #{Time.now} -----------"
    puts "Spot Rate is $%.2f" % stats.spot_rate
    # TODO calculate some basic price movement statistics
    # 1m mavd
    # puts "Order book has #{orderbook[:bids]} open bids and #{orderbook[:asks]} open asks"
    puts "In the past hour, the maximum price movement was $%.2f" % stats.price_history.max
    puts "The highest price in in the past 24 hours was $%.2f" % daily_stats[:high]
    puts "The lowest price in in the past 24 hours was $%.2f" % daily_stats[:low]
    puts "You have #{stats.open_order_count} open orders."
    stats.print_order_stats
    puts "-------------------------------------------------"

    sleep 3
  end
  exit 0

else

  $stderr.puts ""
  $stderr.puts "No action specified. Try: run, buy, cancel"
  $stderr.puts " e.g."
  $stderr.puts "    bundle exec ruby trader.rb run"
  $stderr.puts ""
  exit 1

end
