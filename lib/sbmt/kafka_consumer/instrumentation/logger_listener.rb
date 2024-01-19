# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class LoggerListener < Karafka::Instrumentation::LoggerListener
        include ListenerHelper
        CUSTOM_ERROR_TYPES = %w[consumer.base.consume_one consumer.inbox.consume_one].freeze

        def on_error_occurred(event)
          type = event[:type]
          error = event[:error]

          # catch here only consumer-specific errors
          # and let default handler to process other
          return super unless CUSTOM_ERROR_TYPES.include?(type)

          tags = {}
          tags[:status] = event[:status] if type == "consumer.inbox.consume_one"

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
          logger.info("Successfully consumed message in #{event.payload[:time]} ms")
        end

        # InboxConsumer events
        def on_consumer_inbox_consumed_one(event)
          logger.tagged(status: event[:status]) do
            logger.info("Successfully consumed message with uuid: #{event[:message_uuid]} in #{event.payload[:time]} ms")
          end
        end
      end
    end
  end
end
