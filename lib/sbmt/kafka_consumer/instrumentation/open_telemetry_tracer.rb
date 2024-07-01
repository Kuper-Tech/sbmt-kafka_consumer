# frozen_string_literal: true

require_relative "tracer"

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class OpenTelemetryTracer < ::Sbmt::KafkaConsumer::Instrumentation::Tracer
        CONSUMED_EVENTS = %w[
          consumer.process_message
          consumer.mark_as_consumed
        ].freeze

        class << self
          def enabled?
            !!@enabled
          end

          attr_writer :enabled
        end

        def enabled?
          self.class.enabled?
        end

        def trace(&block)
          return handle_consumed_one(&block) if @event_id == "consumer.consumed_one"
          return handle_consumed_batch(&block) if @event_id == "consumer.consumed_batch"
          return handle_inbox_consumed_one(&block) if @event_id == "consumer.inbox.consumed_one"
          return handle_common_event(&block) if CONSUMED_EVENTS.include?(@event_id)
          return handle_error(&block) if @event_id == "error.occurred"

          yield
        end

        def handle_consumed_one
          return yield unless enabled?

          consumer = @payload[:caller]
          message = @payload[:message]

          parent_context = ::OpenTelemetry.propagation.extract(message.headers, getter: ::OpenTelemetry::Context::Propagation.text_map_getter)
          span_context = ::OpenTelemetry::Trace.current_span(parent_context).context
          links = [::OpenTelemetry::Trace::Link.new(span_context)] if span_context.valid?

          ::OpenTelemetry::Context.with_current(parent_context) do
            tracer.in_span("consume #{message.topic}", links: links, attributes: consumer_attrs(consumer, message), kind: :consumer) do
              yield
            end
          end
        end

        def handle_consumed_batch
          return yield unless enabled?

          consumer = @payload[:caller]
          messages = @payload[:messages]

          links = messages.filter_map do |m|
            parent_context = ::OpenTelemetry.propagation.extract(m.headers, getter: ::OpenTelemetry::Context::Propagation.text_map_getter)
            span_context = ::OpenTelemetry::Trace.current_span(parent_context).context
            ::OpenTelemetry::Trace::Link.new(span_context) if span_context.valid?
          end

          tracer.in_span("consume batch", links: links, attributes: batch_attrs(consumer, messages), kind: :consumer) do
            yield
          end
        end

        def handle_inbox_consumed_one
          return yield unless enabled?

          inbox_name = @payload[:inbox_name]
          event_name = @payload[:event_name]
          status = @payload[:status]

          inbox_attributes = {
            "inbox.inbox_name" => inbox_name,
            "inbox.event_name" => event_name,
            "inbox.status" => status
          }.compact

          tracer.in_span("inbox #{inbox_name} process", attributes: inbox_attributes, kind: :consumer) do
            yield
          end
        end

        def handle_common_event(&block)
          return yield unless enabled?

          if @payload[:inbox_name].present?
            handle_inbox_consumed_one(&block)
          else
            handle_consumed_one(&block)
          end
        end

        def handle_error
          return yield unless enabled?

          current_span = OpenTelemetry::Trace.current_span
          current_span&.status = OpenTelemetry::Trace::Status.error

          yield
        end

        private

        def tracer
          ::Sbmt::KafkaConsumer::Instrumentation::OpenTelemetryLoader.instance.tracer
        end

        def consumer_attrs(consumer, message)
          attributes = {
            "messaging.system" => "kafka",
            "messaging.destination" => message.topic,
            "messaging.destination_kind" => "topic",
            "messaging.kafka.consumer_group" => consumer.topic.consumer_group.id,
            "messaging.kafka.partition" => message.partition,
            "messaging.kafka.offset" => message.offset
          }

          message_key = extract_message_key(message.key)
          attributes["messaging.kafka.message_key"] = message_key if message_key

          attributes.compact
        end

        def batch_attrs(consumer, messages)
          message = messages.first
          {
            "messaging.system" => "kafka",
            "messaging.destination" => message.topic,
            "messaging.destination_kind" => "topic",
            "messaging.kafka.consumer_group" => consumer.topic.consumer_group.id,
            "messaging.batch_size" => messages.count,
            "messaging.first_offset" => messages.first.offset,
            "messaging.last_offset" => messages.last.offset
          }.compact
        end

        def extract_message_key(key)
          # skip encode if already valid utf8
          return key if key.nil? || (key.encoding == Encoding::UTF_8 && key.valid_encoding?)

          key.encode(Encoding::UTF_8)
        rescue Encoding::UndefinedConversionError
          nil
        end
      end
    end
  end
end
