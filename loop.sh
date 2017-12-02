#!/bin/sh

# set to every 3 hours
# 0.01 ETH @ @
# 8x/day @ ~$3/each = ~$25/day)
time=$((3 * 60 * 60))

while [ 1 ]; do
  bundle exec ruby trader.rb buy
  sleep $time
done
