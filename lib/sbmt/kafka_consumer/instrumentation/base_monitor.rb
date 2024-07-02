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
          consumer.process_message
          consumer.mark_as_consumed
        ].freeze

        def initialize
          super
          SBMT_KAFKA_CONSUMER_EVENTS.each { |event_id| notifications_bus.register_event(event_id) }
        end

        def instrument(_event_id, _payload = EMPTY_HASH, &block)
          super
        end
      end
    end
  end
end
