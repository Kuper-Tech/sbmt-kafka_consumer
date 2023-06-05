# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class BaseConsumer < SbmtKarafka::BaseConsumer
      attr_reader :trace_id

      def self.consumer_klass(**attrs)
        self
      end

      def consume
        messages.each do |message|
          @trace_id = SecureRandom.base58

          ::Sbmt::KafkaConsumer.monitor.instrument("consumer.consumed_one", caller: self, message: message, trace_id: trace_id) do
            logger.tagged(trace_id: trace_id) do
              log_message(message) if log_payload?

              # deserialization process is lazy (and cached)
              # so we trigger it explicitly to catch undeserializable message early
              message.payload

              process_message(message)

              mark_as_consumed!(message)
            rescue SkipUndeserializableMessage => ex
              logger.warn("skipping undeserializable message: #{ex.message}")
              instrument_error(ex, message)
            rescue => ex
              instrument_error(ex, message)
              raise ex
            end
          end
        end
      end

      private

      # can be overridden in consumer to enable message logging
      def log_payload?
        false
      end

      def logger
        ::Sbmt::KafkaConsumer.logger
      end

      def process_message(_message)
        raise NotImplementedError, "Implement this in a subclass"
      end

      def log_message(message)
        logger.info("#{message.raw_payload}, message_key: #{message.metadata.key}, message_headers: #{message.metadata.headers}")
      end

      def instrument_error(error, message)
        ::Sbmt::KafkaConsumer.monitor.instrument(
          "error.occurred",
          error: error,
          caller: self,
          message: message,
          type: "consumer.base.consume_one"
        )
      end
    end
  end
end
