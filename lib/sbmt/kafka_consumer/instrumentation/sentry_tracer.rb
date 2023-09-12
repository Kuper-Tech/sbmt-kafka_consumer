# frozen_string_literal: true

require "sentry-ruby"
require_relative "tracer"

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class SentryTracer < ::Sbmt::KafkaConsumer::Instrumentation::Tracer
        CONSUMER_ERROR_TYPES = %w[
          consumer.base.consume_one
          consumer.inbox.consume_one
        ].freeze

        def trace(&block)
          return handle_consumed_one(&block) if @event_id == "consumer.consumed_one"
          return handle_error(&block) if @event_id == "error.occurred"

          yield
        end

        def handle_consumed_one
          return yield unless ::Sentry.initialized?

          consumer = @payload[:caller]
          message = @payload[:message]
          trace_id = @payload[:trace_id]

          scope, transaction = start_transaction(trace_id, consumer, message)

          begin
            yield
          rescue
            finish_transaction(transaction, 500)
            raise
          end

          finish_transaction(transaction, 200)
          scope.clear
        end

        def handle_error
          return yield unless ::Sentry.initialized?

          exception = @payload[:error]
          return yield unless exception.respond_to?(:message)

          ::Sentry.with_scope do |scope|
            if detailed_logging_enabled?
              message = @payload[:message]
              if message.present?
                contexts = {
                  payload: message_payload(message),
                  metadata: message.metadata
                }
                scope.set_contexts(contexts: contexts)
              end
            end
            ::Sentry.capture_exception(exception)
          end

          yield
        end

        private

        def start_transaction(trace_id, consumer, message)
          scope = ::Sentry.get_current_scope
          scope.set_tags(trace_id: trace_id, topic: message.topic, offset: message.offset)
          scope.set_transaction_name("Sbmt/KafkaConsumer/#{consumer.class.name}")

          transaction = ::Sentry.start_transaction(name: scope.transaction_name, op: "kafka-consumer")

          scope.set_span(transaction) if transaction

          [scope, transaction]
        end

        def finish_transaction(transaction, status)
          return unless transaction

          transaction.set_http_status(status)
          transaction.finish
        end

        def detailed_logging_enabled?
          consumer = @payload[:caller]
          event_type = @payload[:type]

          CONSUMER_ERROR_TYPES.include?(event_type) && consumer.send(:log_payload?)
        end

        def message_payload(message)
          message.payload
        rescue => _ex
          # payload triggers deserialization error
          # so in that case we return raw_payload
          message.raw_payload
        end
      end
    end
  end
end
