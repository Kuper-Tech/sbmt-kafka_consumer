# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class BaseConsumer < Karafka::BaseConsumer
      attr_reader :trace_id

      def self.consumer_klass(skip_on_error: false, middlewares: [])
        Class.new(self) do
          const_set(:SKIP_ON_ERROR, skip_on_error)
          const_set(:MIDDLEWARES, middlewares.map(&:constantize))

          def self.name
            superclass.name
          end
        end
      end

      def consume
        ::Rails.application.executor.wrap do
          if process_batch?
            with_batch_instrumentation(messages) do
              process_batch(messages)
              mark_as_consumed!(messages.last)
            end
          else
            messages.each do |message|
              with_instrumentation(message) { do_consume(message) }
            end
          end
        end
      end

      def process_batch?
        if @process_batch_memoized.nil?
          @process_batch_memoized = respond_to?(:process_batch)
        end
        @process_batch_memoized
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

      def with_batch_instrumentation(messages)
        @trace_id = SecureRandom.base58

        logger.tagged(
          trace_id: trace_id,
          first_offset: messages.first.metadata.offset,
          last_offset: messages.last.metadata.offset
        ) do
          ::Sbmt::KafkaConsumer.monitor.instrument(
            "consumer.consumed_batch",
            caller: self,
            messages: messages,
            trace_id: trace_id
          ) do
            yield
          end
        end
      end

      def do_consume(message)
        log_message(message) if log_payload?

        # deserialization process is lazy (and cached)
        # so we trigger it explicitly to catch undeserializable message early
        message.payload

        call_middlewares(message, middlewares) { process_message(message) }

        mark_as_consumed!(message)
      end

      def skip_on_error
        self.class::SKIP_ON_ERROR
      end

      def middlewares
        self.class::MIDDLEWARES
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

      def call_middlewares(message, middlewares)
        return yield if middlewares.empty?

        chain = middlewares.map { |middleware_class| middleware_class.new }

        traverse_chain = proc do
          if chain.empty?
            yield
          else
            chain.shift.call(message, &traverse_chain)
          end
        end
        traverse_chain.call
      end
    end
  end
end
