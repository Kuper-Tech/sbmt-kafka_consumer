# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      module ListenerHelper
        delegate :logger, to: ::Sbmt::KafkaConsumer

        private

        def consumer_tags(event)
          message = event[:message]
          {
            topic: message.metadata.topic,
            partition: message.metadata.partition
          }
        end

        def inbox_tags(event)
          {
            inbox_name: event[:inbox_name],
            event_name: event[:event_name],
            status: event[:status]
          }
        end

        def error_message(error)
          if error.respond_to?(:message)
            error.message
          elsif error.respond_to?(:failure)
            error.failure
          else
            error.to_s
          end
        end

        def log_backtrace(error)
          if error.respond_to?(:backtrace)
            logger.error(error.backtrace.join("\n"))
          elsif error.respond_to?(:trace)
            logger.error(error.trace)
          end
        end
      end
    end
  end
end
