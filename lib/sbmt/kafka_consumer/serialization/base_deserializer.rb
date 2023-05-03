# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Serialization
      class BaseDeserializer
        attr_reader :skip_decoding_error

        def initialize(skip_decoding_error: false)
          @skip_decoding_error = skip_decoding_error
        end

        def call(_message)
          raise NotImplementedError, "Implement this in a subclass"
        end
      end
    end
  end
end
