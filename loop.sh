#!/bin/sh

# set to every 3 hours
# 0.01 ETH @ $250... 8x day ~= $25/day
# 0.0003 BTC @ $11k... 8x day ~= $24/day
time=$((3 * 60 * 60))

while [ 1 ]; do
  bundle exec ruby trader.rb buy 5USD BTC
  bundle exec ruby trader.rb buy 5USD ETH
  bundle exec ruby trader.rb buy 5USD BCH
  sleep $time
done
