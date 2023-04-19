# frozen_string_literal: true

require "zeitwerk"

module Sbmt
  module KafkaConsumer
    class Error < StandardError; end
    # Your code goes here...
  end
end

loader = Zeitwerk::Loader.new
# we need to set parent dir as gem autoloading root
# see https://github.com/fxn/zeitwerk/issues/138#issuecomment-709640940 for details
loader.push_dir(File.join(__dir__, ".."))
loader.tag = "sbmt-kafka_consumer"
loader.ignore("#{__dir__}/kafka_consumer/version.rb")
loader.setup
loader.eager_load
