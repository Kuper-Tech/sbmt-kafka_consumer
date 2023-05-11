# frozen_string_literal: true

require "zeitwerk"
require "sbmt_karafka"
require "active_record"
require "yabeda"
require "sentry-ruby"
require "anyway_config"
require "thor"
require "dry/types"
require "dry-struct"

require_relative "kafka_consumer/railtie" if defined?(Rails::Railtie)

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

# exclusions from eager loading process
# optional to use, but still managed by zeitwerk
loader.do_not_eager_load("#{__dir__}/kafka_consumer/serialization/protobuf_deserializer.rb")
loader.do_not_eager_load("#{__dir__}/kafka_consumer/testing.rb")
loader.do_not_eager_load("#{__dir__}/kafka_consumer/testing")
loader.do_not_eager_load("#{__dir__}/kafka_consumer/version.rb")

loader.inflector.inflect("cli" => "CLI")

loader.setup
loader.eager_load
