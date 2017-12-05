#!/usr/bin/env ruby

require 'dotenv/load'
require 'coinbase/exchange'
require 'pp'

require_relative 'limit_order'
require_relative 'market_stats'

action = ARGV[0].to_s
amount = ARGV[1].to_f
currency = ARGV[2].to_s

if action.nil? || amount.nil? || currency.nil?
  $stderr.puts "Missing arguments: `action amount currency`"
  $stderr.puts "e.g. 'buy 0.01 ETH'"
  exit 1
end

def client
  @client ||= Coinbase::Exchange::Client.new(ENV['GDAX_API_KEY'], ENV['GDAX_API_SECRET'], ENV['GDAX_PASSPHRASE'])
end

def buy(amount, currency)
  order = LimitOrder.new(client, amount, currency)
  order.buy!

  # Try buying for ~10 minutes before giving up
  start_time = Time.now
  max_attempts = 100
  sleep_time = 5

  puts "Going to try buying #{max_attempts} times..."
  (0..max_attempts).each do |i|
    current_price = order.current_price.to_f
    paid_price = order.order_bid_price.to_f
    drift = current_price - paid_price
    drift_percentage = drift.abs / paid_price
    puts "##{i}: Status=#{order.status}   Bid is #{paid_price.to_f}   Spot rate is $#{current_price.to_f}   Drift is #{drift.round(2)} (#{(drift_percentage * 100.0).round(2)}%)"

    if order.status == 'done'
      puts "Order filled! Nice job!"
      puts "Took #{(Time.now - start_time).round} seconds"
      exit 0
    end

    if order.status == 'open'
      # If our bid has drifted too far from current price, cancel it and re-bid
      if drift > order.drift_threshold
        puts "Too much drift (threshold=#{order.drift_threshold}), cancelling and re-bidding"
        order.cancel!
        order.buy!
      end
    elsif order.status == 'rejected'
      # Our bid was probably higher than the spot price, try again
      order.buy!
    else
      $stderr.puts "Unknown order status #{order.status.inspect}, halting"
      order.cancel!
      exit 1
    end

    sleep sleep_time
  end

  order.cancel!
  exit 1
end

def cancel_all_orders
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
end

# main()
if action == 'buy'
  buy(amount, currency)
elsif action == 'cancel'
  cancel_all_orders
else
  $stderr.puts ""
  $stderr.puts "No action specified. Try: buy, cancel"
  $stderr.puts " e.g."
  $stderr.puts "    bundle exec ruby trader.rb buy 0.01 ETH"
  $stderr.puts ""
  exit 1
end
