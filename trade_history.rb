#!/bin/env ruby

require 'dotenv/load'
require 'coinbase/exchange'
require 'pp'

# TODO DRY with trader.rb
BASE_PAIR = "BTC"
def client
  @client ||= Coinbase::Exchange::Client.new(
    ENV['GDAX_API_KEY'], ENV['GDAX_API_SECRET'], ENV['GDAX_PASSPHRASE'],
    product_id: "#{BASE_PAIR}-USD" # FIXME allow specifying the pair
  )
end



def aggregate_stats(for_fills)


end


date = '2017-12-26'

fills = client.fills.select do |fill|
  date = Date.parse(fill.created_at)
  w = date.strftime('%y/%m/%d/')
end

puts "Found #{fills.length} for #{date}"

parsed_fills = fills.map do |fill|

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
    fee: fill.fee.to_f,
    side: fill.side,
    coin: fill.product_id.gsub(/\-USD$/,'') # FIXME
  }
end

def print_fill(fill)
  unless fill[:side] == 'buy' || fill[:side] == 'sell'
    raise "Don't know how to deal with fill.side=#{fill[:side].inspect} yet"
  end

  puts "#{fill[:created_at]}: #{fill[:side]} #{fill[:size]} #{fill[:coin]} @ $#{fill[:price]} => $#{fill[:value]} fee=#{fill[:fee].round(2)}"
end

fill_groups = parsed_fills.group_by{|f|
  f[:created_at].strftime('%Y-%m') + ' ' + f[:coin]
}

fill_groups.sort_by{|k,v| k }.each do |group,fills|

  date, coin = group.split(' ')
  next if coin != 'BTC'

  # fills.each{|f| print_fill(f) }

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
  # puts "Bought #{data[:size]} #{coin} in #{fills.length} transactions total=$#{data[:value]}"
  # puts "Avg price: #{avg_price.to_f}"
  # puts "Highest price: #{highest_price}"
  # puts "Lowest price: #{lowest_price}"

end


