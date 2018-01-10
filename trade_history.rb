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




def print_aggregate_stats(fill_groups, print_summary_stats=false)
  results = []
  fill_groups.each do |group,fills|
    date, coin = group.split(' ')

    data = {
      date: date,
      coin: coin,
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

    if print_summary_stats
      $stderr.puts "coin=#{coin} date=#{date}"
      $stderr.puts "Bought #{data[:size]} #{coin} in #{fills.length} transactions total=$#{data[:value]}"
      $stderr.puts "Avg price: #{avg_price.to_f}"
      $stderr.puts "Highest price: #{highest_price}"
      $stderr.puts "Lowest price: #{lowest_price}"
    end

    results << data
  end

  results
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

action = ARGV[0].to_s
$stderr.puts "action=#{action.inspect}"

fills = client.fills.map{|f| parse_fill(f) }
$stderr.puts "Found #{fills.length} trades ..."

if action == 'daily'

  $stderr.puts "\n----- daily stats -----"
  fill_groups = fills.group_by{|f| f[:created_at].strftime('%Y-%m-%d') + ' ' + f[:coin] }.sort_by{|k,v| k }
  print_aggregate_stats(fill_groups)

elsif action == 'monthly'

  $stderr.puts "\n----- monthly stats -----"
  fill_groups = fills.group_by{|f| f[:created_at].strftime('%Y-%m') + ' ' + f[:coin] }.sort_by{|k,v| k }
  print_aggregate_stats(fill_groups, true)

elsif action == 'price_history'

  raise 'Not Yet Implemented'
  # start_time = Date.parse('2017-12-01')
  # end_time = Date.parse('2017-12-28')
  # granularities {60, 300, 900, 3600, 21600, 86400}
  # pp client.price_history(granularity: 86400, start: start_time, end: end_time)
  # exit

else

  $stderr.puts "\n----- every trade -----"
  fills.sort_by{|f| f[:created_at] }.each do |fill|
    print_fill(fill)
  end

end

