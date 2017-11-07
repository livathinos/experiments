#!/usr/bin ruby

require 'optparse'

#
# Calculates storage cost per month.
#
# The following example will calculate the cost of saving 100GB of data every
# month into a BigQuery instance for a 12 month period. It will take into
# account both for short term and long term storage costs:
#
#   > ruby storage_cost.rb --time 12 \
#                          --data 100 \
#                          --cost 0.02 \
#                          --alternative-cost 0.01 \
#                          --cost-switch-period 3
#

class StorageCost
  COST = 0.02
  ALTERNATIVE_COST = 0.01
  THREE_MONTHS = 3

  def initialize(args)

    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: example.rb [options]"
      opts.on("-t=n", "--time=n", "Timeframe in months") do |time|
        options[:time] = time
      end

      opts.on("-d=n", "--data=n", "Data in GB per month") do |data|
        options[:data] = data
      end

      opts.on("-c=n", "--cost=n", "Storage cost in USD") do |cost|
        options[:cost] = cost
      end

      opts.on("-ca=n", "--alternative-cost=n",
              "Alternative storage cost in USD. e.g. Long term storage pricing") do |alternative_cost|
        options[:alternative_cost] = alternative_cost
      end

      opts.on("-cp=n", "--cost-switch-period=n",
              "Period in months after which data is priced with alternative storage pricing") do |cost_switch_period|
        options[:cost_switch_period] = cost_switch_period
      end

    end.parse!

    @timeframe = options[:time].to_i
    @data_per_month = options[:data].to_i
    @cost = options.fetch(:cost, COST)
    @alternative_cost = options.fetch(:alternative_cost, ALTERNATIVE_COST).to_f
    @cost_switch_period = options.fetch(:cost_switch_period, THREE_MONTHS).to_i
  end

  def run
    puts long_term_storage_cost + short_term_storage_cost
  end

  private

  attr_reader :data_per_month, :timeframe, :cost, :alternative_cost, :cost_switch_period

  def long_term_storage_months
    if timeframe > cost_switch_period
      timeframe - cost_switch_period
    else
      timeframe
    end
  end

  def long_term_storage_cost
    if timeframe_over_three_months?
      accumulating_data = data_per_month

      (1..long_term_storage_months).inject(0) do |acc_cost, n|
        acc_cost += alternative_cost * accumulating_data
        accumulating_data += data_per_month

        acc_cost
      end
    else
      0
    end
  end

  def short_term_storage_cost
    if timeframe_over_three_months?
      accumulating_data = data_per_month

      pre_cost_switch_period_cost =
        (1..cost_switch_period).inject(0) do |acc_cost, n|
          acc_cost += cost * accumulating_data
          accumulating_data += data_per_month

          acc_cost
        end

      pre_cost_switch_period_cost + post_cost_switch_period_cost
    else
      (1..timeframe).inject(0) do |acc, n|
        acc += cost * data_per_month * n
      end
    end
  end

  def timeframe_over_three_months?
    timeframe > cost_switch_period
  end

  def post_cost_switch_period_cost
    long_term_storage_months * data_per_month * cost_switch_period * cost
  end
end

StorageCost.new(ARGV).run
