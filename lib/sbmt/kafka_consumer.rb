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

require "anyway/rails" if defined?(Rails)
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

    class SkipUndeserializableMessage < Error; end
  end
end

loader = Zeitwerk::Loader.new
# we need to set parent dir as gem autoloading root
# see https://github.com/fxn/zeitwerk/issues/138#issuecomment-709640940 for details
loader.push_dir(File.join(__dir__, ".."))
loader.tag = "sbmt-kafka_consumer"

# protobuf is an optional dependency
loader.do_not_eager_load("#{__dir__}/kafka_consumer/serialization/protobuf_deserializer.rb")

# completely ignore testing helpers
# because testing.rb just requires some files and does not contain any constants (e.g. Testing) which Zeitwerk expects
loader.ignore("#{__dir__}/kafka_consumer/testing.rb")
loader.ignore("#{__dir__}/kafka_consumer/testing")

loader.inflector.inflect("cli" => "CLI")
loader.inflector.inflect("version" => "VERSION")

loader.setup
loader.eager_load
