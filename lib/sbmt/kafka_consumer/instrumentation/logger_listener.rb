# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class LoggerListener < BaseListener
        ALLOWED_ERROR_TYPES = %w[consumer.base.consume_one consumer.inbox.consume_one].freeze

        def on_error_occurred(event)
          type = event[:type]
          error = event[:error]

          # catch only consumer-specific errors
          return unless ALLOWED_ERROR_TYPES.include?(type)

          tags = {}
          tags.merge!(consumer_tags(event)) if type == "consumer.base.consume_one"
          tags.merge!(inbox_tags(event)) if type == "consumer.inbox.consume_one"

          logger.tagged(
            type: type,
            **tags
          ) do
            logger.error(error_message(error))
            log_backtrace(error)
          end
        end

        # BaseConsumer events
        def on_consumer_consumed_one(event)
          logger.tagged(
            **consumer_tags(event)
          ) do
            logger.info("Successfully consumed message")
          end
        end

        # InboxConsumer events
        def on_consumer_inbox_consumed_one(event)
          logger.tagged(
            **inbox_tags(event)
          ) do
            logger.info("Successfully consumed message with uuid: #{event[:message_uuid]}")
          end
        end
      end
    end
  end
end
