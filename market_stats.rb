class MarketStats
  attr_accessor :client

  def initialize(_client)
    self.client = _client
  end

  def spot_rate
    client.last_trade do |resp|
      return resp.price
    end
  end

  def orderbook_stats
    client.orderbook(level: 3)do |resp|
      return { bids: resp.bids.count, asks: resp.asks.count }
    end
  end

  # Defaults to the last hour
  def price_history(seconds_ago=3600)
    client.price_history(start: Time.now - seconds_ago, granularity: 60) do |resp|
      candles = resp.map { |candle| candle.high - candle.low }
      return candles
    end
  end

  def daily_stats
    client.daily_stats do |resp|
      return { high: resp.high, low: resp.low }
    end
  end

  def open_order_count
    client.orders(status: "open") do |resp|
      return resp.count
    end
  end

  def print_order_stats
    orders = client.orders(status: "open")

    orders.each do |order|
      bid = order.price.to_f.round(2)
      current = spot_rate.to_f.round(2)
      difference = (bid - current).round(2)
      puts "Order: #{order.id}"
      puts "Bid: #{bid.to_f} (#{difference})"

      time_ago = Time.now - Time.parse(order.created_at)
      puts "Created #{time_ago.to_i}s ago"
    end
  end
end
