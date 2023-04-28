# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class BaseMonitor < SbmtKarafka::Instrumentation::Monitor
        # karafka consuming is based around batch-processing
        # so we need these per-message custom events
        SBMT_KAFKA_CONSUMER_EVENTS = %w[
          consumer.consumed_one
          consumer.inbox.consumed_one
        ].freeze

        DEFAULT_TRACEABLE_EVENTS = []

        def initialize
          super
          SBMT_KAFKA_CONSUMER_EVENTS.each { |event_id| notifications_bus.register_event(event_id) }
        end

        def instrument(event_id, payload = EMPTY_HASH, &block)
          # Always run super, so the default instrumentation pipeline works
          return super unless traceable_events.include?(event_id)

          trace(event_id, payload) { super }
        end

        private

        def trace(_event_id, _payload, &block)
          raise NotImplementedError, "Implement this in a subclass"
        end

        def traceable_events
          DEFAULT_TRACEABLE_EVENTS
        end
      end
    end
  end
end
