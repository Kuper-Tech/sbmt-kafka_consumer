# frozen_string_literal: true

require_relative "consumer_mapper/base"

module Sbmt
  module KafkaConsumer
    module Routing
      # karafka v2 (before 2.4) consumer group name mapper
      class KarafkaV2ConsumerMapper < ConsumerMapper::Base
        def call(raw_consumer_group_name)
          "#{Karafka::App.config.client_id}_#{raw_consumer_group_name}"
        end
      end
    end
  end
end
