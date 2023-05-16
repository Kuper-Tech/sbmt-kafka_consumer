# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class YabedaConfigurer
      SIZE_BUCKETS = [1, 10, 100, 1000, 10_000, 100_000, 1_000_000].freeze
      LATENCY_BUCKETS = [0.0001, 0.001, 0.01, 0.1, 1.0, 10, 100, 1000].freeze
      DELAY_BUCKETS = [1, 3, 10, 30, 100, 300, 1000, 3000, 10_000, 30_000].freeze
      def self.configure
        Yabeda.configure do
          group :kafka_api do
            counter :calls,
              tags: %i[client broker],
              comment: "API calls"
            histogram :latency,
              tags: %i[client broker],
              unit: :seconds,
              buckets: LATENCY_BUCKETS,
              comment: "API latency"
            histogram :request_size,
              tags: %i[client broker],
              unit: :bytes,
              buckets: SIZE_BUCKETS,
              comment: "API request size"
            histogram :response_size,
              tags: %i[client broker],
              unit: :bytes,
              buckets: SIZE_BUCKETS,
              comment: "API response size"
            counter :errors,
              tags: %i[client broker],
              comment: "API errors"
          end

          group :kafka_consumer do
            counter :consumer_group_rebalances,
              tags: %i[client group_id state],
              comment: "Consumer group rebalances"

            counter :process_messages,
              tags: %i[client group_id topic partition],
              comment: "Messages consumed"

            counter :process_message_errors,
              tags: %i[client group_id topic partition],
              comment: "Messages failed to process"

            histogram :process_message_latency,
              tags: %i[client group_id topic partition],
              unit: :seconds,
              buckets: LATENCY_BUCKETS,
              comment: "Consumer latency"

            gauge :offset_lag,
              tags: %i[client group_id topic partition],
              comment: "Consumer offset lag"

            gauge :time_lag,
              tags: %i[client group_id topic partition],
              comment: "Consumer time lag"

            counter :process_batch_errors,
              tags: %i[client group_id topic partition],
              comment: "Messages failed to process"

            histogram :process_batch_latency,
              tags: %i[client group_id topic partition],
              unit: :seconds,
              buckets: LATENCY_BUCKETS,
              comment: "Consumer batch latency"

            histogram :batch_size,
              tags: %i[client group_id topic partition],
              unit: :bytes,
              buckets: SIZE_BUCKETS,
              comment: "Consumer batch size"

            counter :leave_group_errors,
              tags: %i[client group_id],
              comment: "Consumer group leave errors"

            gauge :pause_duration,
              tags: %i[client group_id topic partition],
              comment: "Consumer pause duration"

            counter :inbox_consumes,
              tags: %i[inbox_name event_name status],
              comment: "Inbox item consumes"
          end
        end
      end
    end
  end
end
