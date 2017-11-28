class LimitOrder
  attr_accessor :order_id, :client

  def initialize(_client)
    self.client = _client
  end

  def bid_amount
    # GDAX's minimum
    0.01
  end

  def bid_price
    current_price - 100
  end

  def current_price
    stats = MarketStats.new(client)
    stats.spot_rate.to_f
  end

  def buy!
    puts "Initiating limit buy order for #{bid_amount} ETH @ $#{bid_price} ..."
    client.bid(
      bid_amount,
      bid_price.round(2),
      type: "limit",
      time_in_force: "GTC",
      post_only: true # only act as a market maker (no fees)
    ) { |resp|
      self.order_id = resp.id
      puts "Placed order for #{bid_amount} @ #{bid_price} Order ID is #{order_id}"
    }
  end

  def info
    check_order_id
    client.order(order_id)
  rescue Coinbase::Exchange::NotFoundError
    $stderr.puts "Error, order #{order_id} not found"
  end

  def status
    info && info['status']
  end

  def cancel!
    check_order_id
    client.cancel(order_id) do
      puts "Order #{order_id} canceled successfully"
    end
  end

  protected

  def check_order_id
    if order_id.nil? || order_id.empty?
      raise "Error, missing order_id"
    end
  end
end