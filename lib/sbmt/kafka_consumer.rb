# frozen_string_literal: true

require "zeitwerk"
require "sbmt_karafka"
require "active_record"
require "yabeda"
require "sentry-ruby"

module Sbmt
  module KafkaConsumer
    class << self
      delegate :monitor, to: SbmtKarafka

      def logger
        @logger ||= Logger.new
      end
    end
    class Error < StandardError; end
  end
end

loader = Zeitwerk::Loader.new
# we need to set parent dir as gem autoloading root
# see https://github.com/fxn/zeitwerk/issues/138#issuecomment-709640940 for details
loader.push_dir(File.join(__dir__, ".."))
loader.tag = "sbmt-kafka_consumer"
loader.ignore("#{__dir__}/kafka_consumer/version.rb")
loader.ignore("#{__dir__}/kafka_consumer/testing.rb")
loader.ignore("#{__dir__}/kafka_consumer/testing/**/*.rb")
loader.setup
loader.eager_load

require_relative "kafka_consumer/railtie" if defined?(Rails::Railtie)
