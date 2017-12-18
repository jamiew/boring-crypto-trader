class LimitOrder
  attr_accessor :client, :amount,
                :order_id, :order_bid_price, :order_bid_amount

  def initialize(_client, _amount)
    self.client = _client

    if _amount =~ /USD/
      self.amount = ("%.5f" % (_amount.gsub('USD','').to_f / current_price)).to_f
    else
      self.amount = _amount.to_f
    end
  end

  def test?
    ENV['TEST']
  end

  def bid_price
    current_price - bid_discount
  end

  # In USD
  def bid_discount
    test? && 100 || 0.1
  end

  # In USD
  def drift_threshold
    test? && 102 || 1
  end

  def current_price
    stats = MarketStats.new(client)
    stats.spot_rate.to_f
  end

  def usd_purchase_price
    "%.2f" % (amount * bid_price)
  end

  def buy!
    puts "-----------"
    puts "Initiating limit buy order for #{amount} #{TRADING_PAIR} @ $#{bid_price} ($#{usd_purchase_price}) ..."
    puts "TEST MODE" if test?
    client.bid(
      amount,
      bid_price.round(2),
      type: "limit",
      time_in_force: "GTC",
      post_only: true # only act as a market maker (no fees)
    ) { |resp|
      self.order_id = resp.id
      self.order_bid_price = bid_price
      self.order_bid_amount = amount
      puts "Success. Order ID is #{order_id}"
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