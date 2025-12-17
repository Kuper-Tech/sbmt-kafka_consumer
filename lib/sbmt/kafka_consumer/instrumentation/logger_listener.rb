# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class LoggerListener < Karafka::Instrumentation::LoggerListener
        include ListenerHelper

        CUSTOM_ERROR_TYPES = %w[consumer.base.consume_one consumer.inbox.consume_one].freeze
        VALID_LOG_LEVELS = %i[error warn].freeze

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
            stacktrace: log_backtrace(error),
            **tags
          ) do
            log_level = event[:log_level] || :error
            if VALID_LOG_LEVELS.include?(log_level)
              logger.public_send(log_level, error_message(error))
            else
              raise "Invalid log level #{log_level}"
            end
          end
        end

        # BaseConsumer events
        def on_consumer_consumed_one(event)
          log_with_tags(log_tags(event), "Successfully consumed message")
        end

        def on_consumer_mark_as_consumed(event)
          log_with_tags(log_tags(event), "Processing message")
        end

        def on_consumer_process_message(event)
          log_with_tags(log_tags(event), "Commit offset")
        end

        # InboxConsumer events
        def on_consumer_inbox_consumed_one(event)
          log_tags = log_tags(event).merge!(status: event[:status])
          msg = "Successfully consumed message with uuid: #{event[:message_uuid]}"

          log_with_tags(log_tags, msg)
        end

        private

        def log_tags(event)
          metadata = event.payload[:message].metadata

          {
            kafka: {
              topic: metadata.topic,
              partition: metadata.partition,
              key: metadata.key,
              offset: metadata.offset,
              consumer_group: event.payload[:caller].topic.consumer_group.id,
              consume_duration_ms: event.payload[:time]
            }
          }
        end

        def log_with_tags(log_tags, msg)
          return unless logger.respond_to?(:tagged)

          logger.tagged(log_tags) do
            logger.send(:info, msg)
          end
        end
      end
    end
  end
end
