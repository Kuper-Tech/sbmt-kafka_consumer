# frozen_string_literal: true

require "rspec"

Dir["#{__dir__}/testing/shared_contexts/*.rb"].sort.each { |f| require f }
