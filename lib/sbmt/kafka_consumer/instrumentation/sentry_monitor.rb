# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class SentryMonitor < BaseMonitor
        delegate :logger, to: ::Sbmt::KafkaConsumer

        CONSUMER_ERROR_TYPES = %w[
          consumer.base.consume_one
          consumer.inbox.consume_one
        ].freeze

        TRACEABLE_EVENTS = %w[
          consumer.consumed_one
          error.occurred
        ].freeze

        private

        def traceable_events
          TRACEABLE_EVENTS
        end

        def trace(event_id, payload, &block)
          return yield unless ::Sentry.initialized?

          case event_id
          when "consumer.consumed_one"
            handle_consumed_one(payload, &block)
          when "error.occurred"
            handle_error(payload, &block)
          else
            raise ArgumentError, "unknown event_id: #{event_id}"
          end
        end

        def handle_consumed_one(payload, &block)
          message = payload[:message]
          trace_id = payload[:trace_id]

          with_sentry_transaction(trace_id, message, &block)
        end

        def handle_error(payload)
          return yield unless payload[:error].respond_to?(:message)

          consumer = payload[:caller]
          event_type = payload[:type]

          Sentry.with_scope do |scope|
            message = payload[:message]
            # if detailed logging is enabled
            # send payload to Sentry
            if consumer_event_type?(event_type) && detailed_logging_enabled?(consumer)
              scope.set_contexts(contexts: {
                payload: message_payload(message),
                metadata: message.metadata
              })
            end
            Sentry.capture_exception(payload[:error])
          end

          yield
        end

        def with_sentry_transaction(trace_id, message, &block)
          scope, transaction = start_transaction(trace_id, message)

          begin
            yield
          rescue
            finish_transaction(transaction, 500)
            raise
          end

          finish_transaction(transaction, 200)
          scope.clear
        end

        def start_transaction(trace_id, message)
          scope = ::Sentry.get_current_scope
          scope.set_tags(trace_id: trace_id, topic: message.topic, offset: message.offset)
          scope.set_transaction_name("Sbmt/KarafkaConsumer/#{self.class.name}")

          transaction = ::Sentry.start_transaction(name: scope.transaction_name, op: "kafka-consumer")

          scope.set_span(transaction) if transaction

          [scope, transaction]
        end

        def finish_transaction(transaction, status)
          return unless transaction

          transaction.set_http_status(status)
          transaction.finish
        end

        def message_payload(message)
          message.payload
        rescue => _ex
          # payload triggers deserializations error
          # so in that case we return raw_payload
          message.raw_payload
        end

        def consumer_event_type?(event_type)
          CONSUMER_ERROR_TYPES.include?(event_type)
        end

        def detailed_logging_enabled?(consumer)
          consumer.send(:log_payload?)
        end
      end
    end
  end
end
