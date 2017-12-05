class LimitOrder
  attr_accessor :client, :amount, :currency,
                :order_id, :order_bid_price, :order_bid_amount

  def initialize(_client, _amount, _currency)
    self.client = _client
    self.amount = _amount
    self.currency = _currency
  end

  def bid_price
    current_price - bid_discount
  end

  # In USD
  def bid_discount
    ENV['TEST'] && 100 || 0.1
  end

  # In USD
  def drift_threshold
    1
  end

  def current_price
    stats = MarketStats.new(client)
    stats.spot_rate.to_f
  end

  def buy!
    puts "Initiating limit buy order for #{amount} #{currency} @ $#{bid_price} ..."
    client.bid(
      amount,
      bid_price.round(2),
      product_id: "#{currency}-USD",
      type: "limit",
      time_in_force: "GTC",
      post_only: true # only act as a market maker (no fees)
    ) { |resp|
      self.order_id = resp.id
      self.order_bid_price = bid_price
      self.order_bid_amount = amount
      puts "Placed order for #{amount} @ #{bid_price}"
      puts "Order ID is #{order_id}"
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
