# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Serialization
      class NullDeserializer
        def call(message)
          message.raw_payload
        end
      end
    end
  end
end
