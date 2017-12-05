#!/bin/sh

# set to every 3 hours
# 0.01 ETH @ $250... 8x day ~= $25/day
# 0.0002 BTC @ $11k... 8x day ~= $16/day
time=$((3 * 60 * 60))

while [ 1 ]; do
  # bundle exec ruby trader.rb buy 0.0002 BTC
  bundle exec ruby trader.rb buy 0.01 ETH
  sleep $time
done
