#!/usr/bin ruby

require 'byebug'
require 'optparse'

#
# Calculates query cost per month.
#
# The following example will calculate the cost of saving 100GB of data every
# month into a BigQuery instance, and querying the accumulating data 30 times
# per month, for a total of 12 months:
#
#   > ruby query_cost.rb --time 12 --queries 30 --data 100 --cost 0.005
#

class QueryCost
  COST = 0.0048

  def initialize(args)

    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: example.rb [options]"
      opts.on("-t=n", "--time=n", "Timeframe in months") do |time|
        options[:time] = time
      end

      opts.on("-q=n", "--queries=n", "Number of queries per month") do |queries|
        options[:queries] = queries
      end

      opts.on("-d=n", "--data=n", "Data in GB per month") do |data|
        options[:data] = data
      end

      opts.on("-c=n", "--cost=n", "Cost in USD per GB") do |cost|
        options[:cost] = cost
      end
    end.parse!

    @timeframe = options[:time].to_i
    @queries = options[:queries].to_i
    @data_per_month = options[:data].to_i
    @cost = options.fetch(:cost, COST).to_f
  end

  def run
    accumulated_data = data_per_month

    total_cost = (1..timeframe).inject(0) do |acc_cost, month|
      monthly_cost =  cost * queries * accumulated_data

      accumulated_data += data_per_month

      acc_cost + monthly_cost
    end

    puts total_cost
  end

  private

  attr_reader :data_per_month, :timeframe, :queries, :cost
end

QueryCost.new(ARGV).run
