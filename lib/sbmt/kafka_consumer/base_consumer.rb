# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class BaseConsumer < SbmtKarafka::BaseConsumer
      DEFAULT_RETRY_DELAY_MULTIPLIER = 10
      DEFAULT_MAX_DB_RETRIES = 5
      DEFAULT_DB_ERRORS_TO_HANDLE = [
        ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
      ].freeze

      attr_reader :trace_id

      def consume
        messages.each do |message|
          @trace_id = SecureRandom.base58

          ::Sbmt::KafkaConsumer.monitor.instrument("consumer.consumed_one", caller: self, message: message, trace_id: trace_id) do
            logger.tagged(trace_id: trace_id) do
              log_message(message) if log_payload?

              with_db_retry { process_message(message) }

              mark_as_consumed!(message)
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

      def with_db_retry
        attempt ||= 1
        yield
      rescue *db_errors_to_handle => e
        attempt += 1

        raise e if attempt > max_db_retries
        ::ActiveRecord::Base.clear_active_connections!

        retry_delay = attempt * DEFAULT_RETRY_DELAY_MULTIPLIER
        sleep(retry_delay)
        retry
      end

      def log_message(message)
        logger.info("#{message.raw_payload}, message_key: #{message.metadata.key}, message_headers: #{message.metadata.headers}")
      end

      def db_errors_to_handle
        @db_errors_to_handle ||= DEFAULT_DB_ERRORS_TO_HANDLE
      end

      def max_db_retries
        @max_db_retries ||= DEFAULT_MAX_DB_RETRIES
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
