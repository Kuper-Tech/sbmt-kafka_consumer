# frozen_string_literal: true

require "sbmt/kafka_consumer"
require "rspec"

Dir["#{__dir__}/testing/*.rb"].sort.each { |f| require f }
Dir["#{__dir__}/testing/shared_contexts/*.rb"].sort.each { |f| require f }
