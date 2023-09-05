# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class YabedaMetricsListener
        include ListenerHelper

        delegate :logger, to: ::Sbmt::KafkaConsumer

        def on_statistics_emitted(event)
          # statistics.emitted is being executed in the main rdkafka thread
          # so we have to do it in async way to prevent thread's hang issues
          report_rdkafka_stats(event)
        end

        def on_consumer_consumed(event)
          # batch processed
          consumer = event[:caller]

          Yabeda.kafka_consumer.batch_size
            .measure(
              consumer_base_tags(consumer),
              consumer.messages.count
            )

          Yabeda.kafka_consumer.process_batch_latency
            .measure(
              consumer_base_tags(consumer),
              time_elapsed_sec(event)
            )

          Yabeda.kafka_consumer.time_lag
            .set(
              consumer_base_tags(consumer),
              consumer.messages.metadata.consumption_lag
            )
        end

        def on_consumer_consumed_one(event)
          # one message processed by any consumer

          consumer = event[:caller]
          Yabeda.kafka_consumer.process_messages
            .increment(consumer_base_tags(consumer))
          Yabeda.kafka_consumer.process_message_latency
            .measure(
              consumer_base_tags(consumer),
              time_elapsed_sec(event)
            )
        end

        def on_consumer_inbox_consumed_one(event)
          # one message processed by InboxConsumer
          Yabeda
            .kafka_consumer
            .inbox_consumes
            .increment(consumer_inbox_tags(event))
        end

        def on_error_occurred(event)
          caller = event[:caller]

          return unless caller.respond_to?(:messages)

          # caller is a BaseConsumer subclass
          case event[:type]
          when "consumer.revoked.error"
            Yabeda.kafka_consumer.leave_group_errors
              .increment(consumer_base_tags(caller))
          when "consumer.consume.error"
            Yabeda.kafka_consumer.process_batch_errors
              .increment(consumer_base_tags(caller))
          when "consumer.base.consume_one"
            Yabeda.kafka_consumer.process_message_errors
              .increment(consumer_base_tags(caller))
          when "consumer.inbox.consume_one"
            Yabeda.kafka_consumer.inbox_consumes
              .increment(consumer_inbox_tags(event))
          end
        end

        private

        def consumer_base_tags(consumer)
          {
            client: SbmtKarafka::App.config.client_id,
            group_id: consumer.topic.consumer_group.id,
            topic: consumer.messages.metadata.topic,
            partition: consumer.messages.metadata.partition
          }
        end

        def consumer_inbox_tags(event)
          caller = event[:caller]

          consumer_base_tags(caller)
            .merge(inbox_tags(event))
        end

        def report_rdkafka_stats(event, async: true)
          thread = Thread.new do
            # https://github.com/confluentinc/librdkafka/blob/master/STATISTICS.md
            stats = event.payload[:statistics]
            consumer_group_id = event.payload[:consumer_group_id]
            consumer_group_stats = stats["cgrp"]
            broker_stats = stats["brokers"]
            topic_stats = stats["topics"]

            report_broker_stats(broker_stats)
            report_consumer_group_stats(consumer_group_id, consumer_group_stats)
            report_topic_stats(consumer_group_id, topic_stats)
          rescue => e
            logger.error("exception happened while reporting rdkafka metrics: #{e.message}")
            logger.error(e.backtrace&.join("\n"))
          end

          thread.join unless async
        end

        def report_broker_stats(brokers)
          brokers.each_value do |broker_statistics|
            # Skip bootstrap nodes
            next if broker_statistics["nodeid"] == -1

            broker_tags = {
              client: SbmtKarafka::App.config.client_id,
              broker: broker_statistics["nodename"]
            }

            Yabeda.kafka_api.calls
              .increment(broker_tags, by: broker_statistics["tx"])
            Yabeda.kafka_api.latency
              .measure(broker_tags, broker_statistics["rtt"]["avg"])
            Yabeda.kafka_api.request_size
              .measure(broker_tags, broker_statistics["txbytes"])
            Yabeda.kafka_api.response_size
              .measure(broker_tags, broker_statistics["rxbytes"])
            Yabeda.kafka_api.errors
              .increment(broker_tags, by: broker_statistics["txerrs"] + broker_statistics["rxerrs"])
          end
        end

        def report_consumer_group_stats(group_id, group_stats)
          return if group_stats.blank?

          cg_tags = {
            client: SbmtKarafka::App.config.client_id,
            group_id: group_id,
            state: group_stats["state"]
          }

          Yabeda.kafka_consumer.consumer_group_rebalances
            .increment(cg_tags, by: group_stats["rebalance_cnt"])
        end

        def report_topic_stats(group_id, topic_stats)
          return if topic_stats.blank?

          topic_stats.each do |topic_name, topic_values|
            topic_values["partitions"].each do |partition_name, partition_statistics|
              next if partition_name == "-1"

              # Skip until lag info is available
              offset_lag = partition_statistics["consumer_lag"]
              next if offset_lag == -1

              Yabeda.kafka_consumer.offset_lag
                .set({
                  client: SbmtKarafka::App.config.client_id,
                  group_id: group_id,
                  topic: topic_name,
                  partition: partition_name
                },
                  offset_lag)
            end
          end
        end

        def time_elapsed_sec(event)
          (event.payload[:time] || 0) / 1000.0
        end
      end
    end
  end
end
