# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::YabedaMetricsListener do
  let(:message) { build(:messages_message) }
  let(:messages) { OpenStruct.new(metadata: build(:messages_batch_metadata), count: 1) }

  describe ".on_statistics_emitted" do
    let(:base_rdkafka_stats) {
      {
        "client_id" => "some-name",
        "brokers" => {
          "kafka:9092/1001" => {
            "name" => "kafka:9092/1001",
            "nodeid" => 1001,
            "nodename" => "kafka:9092",
            "tx_d" => 7,
            "txbytes" => 338,
            "txerrs_d" => 0,
            "rx" => 7,
            "rxbytes" => 827,
            "rxerrs_d" => 0,
            "rtt" => {
              "avg" => 1984
            }
          }
        }
      }.freeze
    }

    context "when only base data is available" do
      let(:event) do
        Karafka::Core::Monitoring::Event.new(
          "statistics.emitted",
          {consumer_group_id: "consumer-group-id", statistics: base_rdkafka_stats}
        )
      end

      it "reports only broker metrics" do
        tags = {client: "some-name", broker: "kafka:9092"}
        expect {
          described_class.new.send(:report_rdkafka_stats, event, async: false)
        }.to measure_yabeda_histogram(Yabeda.kafka_api.latency).with_tags(tags)
          .and measure_yabeda_histogram(Yabeda.kafka_api.request_size).with_tags(tags)
          .and measure_yabeda_histogram(Yabeda.kafka_api.response_size).with_tags(tags)
          .and increment_yabeda_counter(Yabeda.kafka_api.calls).with_tags(tags)
          .and increment_yabeda_counter(Yabeda.kafka_api.errors).with_tags(tags)
          .and not_increment_yabeda_counter(Yabeda.kafka_consumer.consumer_group_rebalances)
          .and not_update_yabeda_gauge(Yabeda.kafka_consumer.offset_lag)
      end
    end

    context "when consumer group data available" do
      let(:event) do
        Karafka::Core::Monitoring::Event.new(
          "statistics.emitted", {
            consumer_group_id: "consumer-group-id",
            statistics: base_rdkafka_stats.merge(
              "cgrp" => {
                "state" => "up",
                "rebalance_cnt" => 0
              }
            )
          }
        )
      end

      it "reports consumer group metrics" do
        expect {
          described_class.new.send(:report_rdkafka_stats, event, async: false)
        }.to increment_yabeda_counter(Yabeda.kafka_consumer.consumer_group_rebalances)
          .with_tags(client: "some-name", group_id: "consumer-group-id", state: "up")
      end
    end

    context "when topic data available" do
      let(:event) do
        Karafka::Core::Monitoring::Event.new(
          "statistics.emitted", {
            consumer_group_id: "consumer-group-id",
            statistics: base_rdkafka_stats.merge(
              "topics" => {
                "topic_with_json_data" => {
                  "topic" => "topic_with_json_data",
                  "partitions" => {
                    "0" => {
                      "partition" => 0,
                      "consumer_lag" => 10
                    },
                    "1" => {
                      "partition" => 1,
                      "consumer_lag" => 10,
                      "fetch_state" => "stopped"
                    },
                    "2" => {
                      "partition" => 2,
                      "consumer_lag" => 10,
                      "fetch_state" => "none"
                    },
                    "-1" => {
                      "partition" => -1,
                      "consumer_lag" => -1
                    }
                  }
                }
              }
            )
          }
        )
      end

      it "reports topic metrics" do
        expect {
          described_class.new.send(:report_rdkafka_stats, event, async: false)
        }.to update_yabeda_gauge(Yabeda.kafka_consumer.offset_lag).with_tags(client: "some-name", group_id: "consumer-group-id", partition: "0", topic: "topic_with_json_data").with(10)
          .and update_yabeda_gauge(Yabeda.kafka_consumer.offset_lag).with_tags(client: "some-name", group_id: "consumer-group-id", partition: "1", topic: "topic_with_json_data").with(0)
          .and update_yabeda_gauge(Yabeda.kafka_consumer.offset_lag).with_tags(client: "some-name", group_id: "consumer-group-id", partition: "2", topic: "topic_with_json_data").with(0)
          .and not_update_yabeda_gauge(Yabeda.kafka_consumer.offset_lag).with_tags(partition: "-1")
      end
    end
  end

  describe ".on_consumer_consumed" do
    let(:topic) { OpenStruct.new(consumer_group: OpenStruct.new(id: "group_id")) }
    let(:consumer) { OpenStruct.new(topic: topic, messages: messages) }
    let(:event) { Karafka::Core::Monitoring::Event.new("consumer.consumed", caller: consumer, time: 10) }

    tags = {
      client: "some-name", group_id: "group_id",
      partition: 0, topic: "topic"
    }

    it "reports batch consuming metrics" do
      expect { described_class.new.on_consumer_consumed(event) }
        .to measure_yabeda_histogram(Yabeda.kafka_consumer.batch_size).with_tags(tags)
        .and measure_yabeda_histogram(Yabeda.kafka_consumer.process_batch_latency).with_tags(tags).with(0.01)
        .and update_yabeda_gauge(Yabeda.kafka_consumer.time_lag).with_tags(tags)
    end
  end

  describe ".on_consumer_consumed_one" do
    let(:topic) { OpenStruct.new(consumer_group: OpenStruct.new(id: "group_id")) }
    let(:consumer) { OpenStruct.new(topic: topic, messages: messages) }
    let(:event) { Karafka::Core::Monitoring::Event.new("consumer.consumed", caller: consumer, time: 10) }

    tags = {
      client: "some-name", group_id: "group_id",
      partition: 0, topic: "topic"
    }

    it "reports consumed message metrics" do
      expect { described_class.new.on_consumer_consumed_one(event) }
        .to increment_yabeda_counter(Yabeda.kafka_consumer.process_messages).with_tags(tags)
        .and measure_yabeda_histogram(Yabeda.kafka_consumer.process_message_latency).with_tags(tags).with(0.01)
    end
  end

  describe ".on_consumer_inbox_consumed_one" do
    let(:inbox_tags) do
      {
        client: "some-name", group_id: "group_id", partition: 0, topic: "topic",
        inbox_name: "inbox", event_name: "event", status: "status"
      }
    end

    let(:topic) { OpenStruct.new(consumer_group: OpenStruct.new(id: "group_id")) }
    let(:consumer) { OpenStruct.new(topic: topic, messages: messages) }

    let(:event) do
      Karafka::Core::Monitoring::Event.new(
        "consumer.consumed",
        inbox_tags.merge(caller: consumer)
      )
    end

    it "increments consumer metric" do
      expect { described_class.new.on_consumer_inbox_consumed_one(event) }
        .to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(inbox_tags)
    end
  end

  describe ".on_error_occurred" do
    let(:topic) { OpenStruct.new(consumer_group: OpenStruct.new(id: "group_id")) }
    let(:consumer) { OpenStruct.new(topic: topic, messages: messages) }
    let(:tags) do
      {
        client: "some-name", group_id: "group_id",
        partition: 0, topic: "topic"
      }
    end

    context "when error type is consumer.revoked.error" do
      let(:event) { Karafka::Core::Monitoring::Event.new("error.occurred", caller: consumer, type: "consumer.revoked.error") }

      it "increments consumer leave group counter" do
        expect { described_class.new.on_error_occurred(event) }
          .to increment_yabeda_counter(Yabeda.kafka_consumer.leave_group_errors)
          .with_tags(tags)
      end
    end

    context "when error type is consumer.consume.error" do
      let(:event) { Karafka::Core::Monitoring::Event.new("error.occurred", caller: consumer, type: "consumer.consume.error") }

      it "increments consumer batch error counter" do
        expect { described_class.new.on_error_occurred(event) }
          .to increment_yabeda_counter(Yabeda.kafka_consumer.process_batch_errors)
          .with_tags(tags)
      end
    end

    context "when error type is consumer.base.consume_one" do
      let(:event) { Karafka::Core::Monitoring::Event.new("error.occurred", caller: consumer, type: "consumer.base.consume_one") }

      it "increments consumer error counter" do
        expect { described_class.new.on_error_occurred(event) }
          .to increment_yabeda_counter(Yabeda.kafka_consumer.process_message_errors)
          .with_tags(tags)
      end
    end

    context "when error type is consumer.inbox.consume_one" do
      let(:inbox_tags) do
        {
          client: "some-name", group_id: "group_id", partition: 0, topic: "topic",
          inbox_name: "inbox", event_name: "event", status: "status"
        }
      end
      let(:event) { Karafka::Core::Monitoring::Event.new("error.occurred", caller: consumer, type: "consumer.inbox.consume_one", **inbox_tags) }

      it "increments inbox consumer metric" do
        expect { described_class.new.on_error_occurred(event) }
          .to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
          .with_tags(inbox_tags)
      end
    end
  end
end
