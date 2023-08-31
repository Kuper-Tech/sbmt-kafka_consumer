# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class BaseConsumer < SbmtKarafka::BaseConsumer
      attr_reader :trace_id

      DEFAULT_RETRY_BACKOFF = ->(attempt) { 4**Math.log(attempt) }
      DEFAULT_MAX_DB_RETRIES = 5
      DEFAULT_DB_ERRORS_TO_HANDLE = [
        ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
      ].freeze

      def self.consumer_klass(skip_on_error: false)
        klass = Class.new(self)
        klass.const_set(:SKIP_ON_ERROR, skip_on_error)
        klass
      end

      def consume
        messages.each do |message|
          with_instrumentation(message) { do_consume(message) }
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

        with_db_retry { process_message(message) }

        mark_as_consumed!(message)
      end

      def skip_on_error
        self.class::SKIP_ON_ERROR
      end

      def with_db_retry
        attempt ||= 0
        yield
      rescue *db_errors_to_handle => e
        attempt += 1

        raise e if attempt >= max_db_retries

        clear_connections!

        retry_delay = retry_backoff.call(attempt)
        logger.info("with_db_retry: #{e.message}, attempt #{attempt}, sleeping for #{retry_delay}s")
        sleep(retry_delay)
        retry
      end

      def clear_connections!
        if multiple_db_handlers?
          ActiveRecord::Base.connection_handlers.each do |role, handler|
            logger.info("Clearing/closing all connections for #{role} role...")
            handler.clear_all_connections!
          end
        else
          logger.info("Clearing/closing all connections...")
          ::ActiveRecord::Base.clear_all_connections!
        end
      end

      def multiple_db_handlers?
        ActiveRecord::Base.respond_to?(:connection_handlers) &&
          # Fix https://jira.sbmt.io/browse/DEX-1280 before removing the upper version bound
          Gem::Version.new(Rails.version) <= Gem::Version.new("7.0.0")
      end

      def db_errors_to_handle
        @db_errors_to_handle ||= DEFAULT_DB_ERRORS_TO_HANDLE
      end

      def max_db_retries
        @max_db_retries ||= DEFAULT_MAX_DB_RETRIES
      end

      def retry_backoff
        @retry_backoff ||= DEFAULT_RETRY_BACKOFF
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
