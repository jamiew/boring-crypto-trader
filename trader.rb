#!/usr/bin/env ruby

require 'dotenv/load'
require 'coinbase/exchange'
require 'pp'

require_relative 'limit_order'

action = ARGV[0].to_s
amount = ARGV[1].to_s
currency = ARGV[2].to_s

if action.nil? || amount.nil? || currency.nil?
  $stderr.puts "Missing arguments: `action amount currency`"
  $stderr.puts "e.g. "
  $stderr.ptus "   buy 0.01 ETH"
  $stderr.puts "or"
  $stderr.puts "   buy \$5 BTC"
  exit 1
end

# Not my favorite way of doing this
BASE_PAIR = currency
QUOTE_PAIR = "USD"
TRADING_PAIR = "#{BASE_PAIR}-#{QUOTE_PAIR}"

def client
  @client ||= Coinbase::Exchange::Client.new(
    ENV['GDAX_API_KEY'], ENV['GDAX_API_SECRET'], ENV['GDAX_PASSPHRASE'],
    product_id: TRADING_PAIR
  )
end

def buy(amount)
  order = LimitOrder.new(client, amount)
  order.buy!

  start_time = Time.now
  max_attempts = 200
  sleep_time = 10

  # Try buying for ~10 minutes before giving up
  puts "Monitoring bid for #{max_attempts} cycles..."
  (0..max_attempts).each do |i|
    sleep sleep_time
    adjust_buy_order_if_necessary(order, i, start_time)
  end

  # If we've gotten this far, just give up
  order.cancel!
  exit 1
rescue Coinbase::Exchange::RateLimitError
  puts "Warning, rate limited on initial buy. Sleeping 5 and retrying..."
  sleep 5
  retry
end

def adjust_buy_order_if_necessary(order, i, start_time)
  current_price = order.current_price.to_f
  paid_price = order.order_bid_price.to_f
  drift = current_price - paid_price
  drift_percentage = drift.abs / paid_price
  puts "##{i}: Status=#{order.status}   Bid is #{paid_price.to_f}   Spot rate is $#{current_price.to_f}   Drift is #{drift.round(2)} (#{(drift_percentage * 100.0).round(2)}%)"

  if order.status == 'done'
    puts "********** Order filled! Nice job! ********"
    puts "Took #{(Time.now - start_time).round} seconds"
    puts "*********************************************"
    puts
    exit 0
  elsif order.status == 'open'
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

rescue Coinbase::Exchange::RateLimitError
  puts "Warning, rate limited. Pausing..."
  sleep 5
end


def cancel_all_orders
  orders = client.orders(status: "open")
  puts "Cancelling #{orders.length} orders..."
  orders.each do |order|
    puts "Cancelling #{order.id}..."
    client.cancel(order.id)
  end
end

# main()
if action == 'buy'
  cancel_all_orders
  begin
    buy(amount)
  rescue Interrupt
    # Catch ctrl-c and get rid of any spare orders
    cancel_all_orders
    raise
  end
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
