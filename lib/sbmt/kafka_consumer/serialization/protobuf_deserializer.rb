# frozen_string_literal: true

require "google/protobuf"

module Sbmt
  module KafkaConsumer
    module Serialization
      class ProtobufDeserializer < BaseDeserializer
        attr_reader :message_decoder

        def initialize(message_decoder_klass:, skip_decoding_error: false)
          super(skip_decoding_error: skip_decoding_error)

          @message_decoder = message_decoder_klass.constantize
        end

        def call(message)
          message_decoder.decode(message.raw_payload)
        rescue Google::Protobuf::ParseError, ArgumentError => e
          raise Sbmt::KafkaConsumer::SkipUndeserializableMessage, "cannot decode message: #{e.message}, payload: #{message.raw_payload}" if skip_decoding_error

          raise
        end
      end
    end
  end
end
