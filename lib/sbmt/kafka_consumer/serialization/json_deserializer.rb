# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Serialization
      class JsonDeserializer < BaseDeserializer
        def call(message)
          # nil payload can be present for example for tombstone messages
          message.raw_payload.nil? ? nil : ::JSON.parse(message.raw_payload)
        end
      end
    end
  end
end
