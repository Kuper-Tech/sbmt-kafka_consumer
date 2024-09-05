# frozen_string_literal: true

require_relative "consumer_mapper/base"

module Sbmt
  module KafkaConsumer
    module Routing
      class KarafkaV1ConsumerMapper < ConsumerMapper::Base
        # karafka v1 consumer group name mapper
        def call(raw_consumer_group_name)
          client_id = ActiveSupport::Inflector.underscore(Karafka::App.config.client_id).tr("/", "_")
          "#{client_id}_#{raw_consumer_group_name}"
        end
      end
    end
  end
end
