# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "bundler/setup"
require "sbmt/kafka_consumer"
require "sbmt/dev/testing/rspec_configuration"
