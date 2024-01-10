# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class BaseConsumer < SbmtKarafka::BaseConsumer
      attr_reader :trace_id

      def self.consumer_klass(skip_on_error: false)
        Class.new(self) do
          const_set(:SKIP_ON_ERROR, skip_on_error)

          def self.name
            superclass.name
          end
        end
      end

      def consume
        ::Rails.application.executor.wrap do
          messages.each do |message|
            with_instrumentation(message) { do_consume(message) }
          end
        end
      end

      private

      def with_instrumentation(message)
        @trace_id = SecureRandom.base58

        logger.tagged(
          trace_id: trace_id,
          topic: message.metadata.topic, partition: message.metadata.partition,
          key: message.metadata.key, offset: message.metadata.offset
        ) do
          ::Sbmt::KafkaConsumer.monitor.instrument(
            "consumer.consumed_one",
            caller: self, message: message, trace_id: trace_id
          ) do
            do_consume(message)
          rescue SkipUndeserializableMessage => ex
            instrument_error(ex, message)
            logger.warn("skipping undeserializable message: #{ex.message}")
          rescue => ex
            instrument_error(ex, message)

            if skip_on_error
              logger.warn("skipping unprocessable message: #{ex.message}, message: #{message_payload(message).inspect}")
            else
              raise ex
            end
          end
        end
      end

      def do_consume(message)
        log_message(message) if log_payload?

        # deserialization process is lazy (and cached)
        # so we trigger it explicitly to catch undeserializable message early
        message.payload

        process_message(message)

        mark_as_consumed!(message)
      end

      def skip_on_error
        self.class::SKIP_ON_ERROR
      end

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
        logger.info("#{message_payload(message).inspect}, message_key: #{message.metadata.key}, message_headers: #{message.metadata.headers}")
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

      def message_payload(message)
        message.payload || message.raw_payload
      end
    end
  end
end
