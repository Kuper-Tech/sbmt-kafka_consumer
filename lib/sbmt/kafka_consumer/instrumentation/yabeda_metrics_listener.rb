# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class YabedaMetricsListener < BaseListener
        def on_consumer_consumed_one(event)
          report_base_metrics(event)
        end

        def on_consumer_inbox_consumed_one(event)
          report_inbox_metrics(event)
        end

        def on_error_occurred(event)
          type = event[:type]

          # catch only consumer-specific errors
          report_base_metrics(event) if type == "consumer.base.consume_one"
          report_inbox_metrics(event) if type == "consumer.inbox.consume_one"
        end

        private

        def report_base_metrics(event)
          Yabeda
            .kafka_consumer
            .consumes
            .increment(consumer_tags(event))
        end

        def report_inbox_metrics(event)
          Yabeda
            .kafka_consumer
            .inbox_consumes
            .increment(inbox_tags(event))
        end
      end
    end
  end
end
