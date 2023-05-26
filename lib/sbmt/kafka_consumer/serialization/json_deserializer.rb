# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Serialization
      class JsonDeserializer < BaseDeserializer
        def call(message)
          # nil payload can be present for example for tombstone messages
          message.raw_payload.nil? ? nil : ::JSON.parse(message.raw_payload)
        rescue JSON::ParserError => e
          raise Sbmt::KafkaConsumer::SkipUndeserializableMessage, "cannot decode message: #{e.message}, payload: #{message.raw_payload}" if skip_decoding_error

          raise
        end
      end
    end
  end
end
