# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class Tracer
        def initialize(event_id, payload)
          @event_id = event_id
          @payload = payload
        end

        def trace(&block)
          yield
        end
      end
    end
  end
end
