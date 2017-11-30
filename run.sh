#!/bin/sh
# Be extra sure we cancel open orders
bundle exec ruby trader.rb cancel
bundle exec ruby trader.rb buy
bundle exec ruby trader.rb cancel
