#!/bin/env ruby

require 'dotenv/load'
require 'coinbase/exchange'
require 'pp'

# TODO DRY with trader.rb
def client
  @client ||= Coinbase::Exchange::Client.new(
    ENV['GDAX_API_KEY'],
    ENV['GDAX_API_SECRET'],
    ENV['GDAX_PASSPHRASE']
  )
end


def aggregate_stats(date, coin, fills)
  data = {
    prices: fills.map{|f| f[:price] },
    price: fills.map{|f| f[:price] }.inject(:+),
    sizes: fills.map{|f| f[:size] },
    size: fills.map{|f| f[:size] }.inject(:+),
    values: fills.map{|f| f[:value] },
    value: fills.map{|f| f[:value] }.inject(:+),
  }

  highest_price = data[:prices].sort[0]
  lowest_price = data[:prices].sort[-1]
  avg_price = (data[:price]/fills.length).to_f

  fields = [date, data[:size], coin, fills.length, data[:value], avg_price.to_f, highest_price, lowest_price]
  puts fields.join(', ')

  # $stderr.puts "Bought #{data[:size]} #{coin} in #{fills.length} transactions total=$#{data[:value]}"
  # $stderr.puts "Avg price: #{avg_price.to_f}"
  # $stderr.puts "Highest price: #{highest_price}"
  # $stderr.puts "Lowest price: #{lowest_price}"
end

def print_fill(fill)
  # puts "#{fill[:created_at]}: #{fill[:side]} #{fill[:size]} #{fill[:coin]} @ $#{fill[:price]} => $#{fill[:value]} fee=#{fill[:fee].round(2)}"
  fields = [fill[:created_at], fill[:size], fill[:coin], fill[:price], fill[:fee], fill[:value]]
  puts fields.join(', ')
end

def parse_fill(fill)
  # "created_at"=>"2017-12-24T04:39:29.041Z",
  # "price"=>"2893.08000000",
  # "size"=>"0.00173000",
  # "fee"=>"0.0000000000000000",
  # "side"=>"buy",
  # "settled"=>true,
  # "usd_volume"=>"5.0050284000000000"

  {
    created_at: Date.parse(fill.created_at),
    price: fill.price.to_f,
    size: fill.size.to_f,
    value: fill.price.to_f * fill.size.to_f,
    # $100 / 5 shares = $20 price-per-share...
    #
    fee: fill.fee.to_f,
    side: fill.side,
    coin: fill.product_id.gsub(/\-USD$/,'') # FIXME
  }
end



#### WORK ###

# Breaks rate limit...
# pp client.trade_history

# start_time = Date.parse('2017-12-01')
# end_time = Date.parse('2017-12-28')
# granularities {60, 300, 900, 3600, 21600, 86400}
# pp client.price_history(granularity: 86400, start: start_time, end: end_time)
# exit


fills = client.fills.map{|f| parse_fill(f) }
$stderr.puts "Found #{fills.length} trades"

$stderr.puts "\n----- every trade -----"
fills.sort_by{|f| f[:created_at] }.each do |fill|
  unless fill[:side] == 'buy' || fill[:side] == 'sell'
    raise "Don't know how to deal with fill.side=#{fill[:side].inspect} yet"
  end

  print_fill(fill)
end


$stderr.puts "\n----- daily stats -----"
fill_groups = fills.group_by{|f| f[:created_at].strftime('%Y-%m-%d') + ' ' + f[:coin] }.sort_by{|k,v| k }
fill_groups.each do |group,fills|
  date, coin = group.split(' ')
  aggregate_stats(date, coin, fills)
end

$stderr.puts "\n----- monthly stats -----"
fill_groups = fills.group_by{|f| f[:created_at].strftime('%Y-%m') + ' ' + f[:coin] }.sort_by{|k,v| k }
fill_groups.each do |group,fills|
  date, coin = group.split(' ')
  aggregate_stats(date, coin, fills)
end


