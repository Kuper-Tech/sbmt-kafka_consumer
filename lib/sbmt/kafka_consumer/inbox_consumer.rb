# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class InboxConsumer < BaseConsumer
      IDEMPOTENCY_HEADER_NAME = "Idempotency-Key"
      DEFAULT_SOURCE = "KAFKA"

      def self.consumer_klass(name:, inbox_item:, event_name: nil, skip_on_error: false)
        Class.new(self) do
          const_set(:INBOX_ITEM_CLASS_NAME, inbox_item)
          const_set(:EVENT_NAME, event_name)
          const_set(:SKIP_ON_ERROR, skip_on_error)

          def self.name
            superclass.name
          end
        end
      end

      def extra_message_attrs(_message)
        {}
      end

      private

      def process_message(message)
        logger.tagged(inbox_name: inbox_name, event_name: event_name) do
          ::Sbmt::KafkaConsumer.monitor.instrument(
            "consumer.inbox.consumed_one", caller: self,
            message: message,
            message_uuid: message_uuid(message),
            inbox_name: inbox_name,
            event_name: event_name,
            status: "success"
          ) do
            process_inbox_item(message)
          end
        end
      end

      def process_inbox_item(message)
        result = Sbmt::Outbox::CreateInboxItem.call(
          inbox_item_class,
          attributes: message_attrs(message)
        )

        if result.failure?
          raise "Failed consuming message for #{inbox_name}, message_uuid: #{message_uuid(message)}: #{result}"
        end

        item = result.success
        item.track_metrics_after_consume if item.respond_to?(:track_metrics_after_consume)
      rescue ActiveRecord::RecordNotUnique
        instrument_error("Skipped duplicate message for #{inbox_name}, message_uuid: #{message_uuid(message)}", message, "duplicate")
      rescue => ex
        if skip_on_error
          logger.warn("skipping unprocessable message for #{inbox_name}, message_uuid: #{message_uuid(message)}")
          instrument_error(ex, message, "skipped")
        else
          instrument_error(ex, message)
        end
        raise ex
      end

      def message_attrs(message)
        attrs = {
          proto_payload: message.raw_payload,
          options: {
            headers: message.metadata.headers.dup,
            group_id: topic.consumer_group.id,
            topic: message.metadata.topic,
            partition: message.metadata.partition,
            source: DEFAULT_SOURCE
          }
        }

        if message_uuid(message)
          attrs[:uuid] = message_uuid(message)
        end

        # if message has no uuid, it will be generated later in Sbmt::Outbox::CreateInboxItem

        attrs[:event_key] = if message.metadata.key.present?
          message.metadata.key
        elsif inbox_item_class.respond_to?(:event_key)
          inbox_item_class.event_key(message)
        else
          # if message has no partitioning key
          # set it to something random and monotonically increasing like offset
          message.offset
        end

        attrs[:event_name] = event_name if inbox_item_class.has_attribute?(:event_name)

        attrs.merge(extra_message_attrs(message))
      end

      def message_uuid(message)
        message.metadata.headers.fetch(IDEMPOTENCY_HEADER_NAME, nil).presence
      end

      def inbox_item_class
        @inbox_item_class ||= self.class::INBOX_ITEM_CLASS_NAME.constantize
      end

      def event_name
        @event_name ||= self.class::EVENT_NAME
      end

      def inbox_name
        inbox_item_class.box_name
      end

      def instrument_error(error, message, status = "failure")
        ::Sbmt::KafkaConsumer.monitor.instrument(
          "error.occurred",
          error: error,
          caller: self,
          message: message,
          inbox_name: inbox_name,
          event_name: event_name,
          status: status,
          type: "consumer.inbox.consume_one"
        )
      end
    end
  end
end
