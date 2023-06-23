# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Config, type: :config do
  context "when app initialized" do
    let(:default_env) {
      {
        "KAFKA_CONSUMER_AUTH__KIND" => "sasl_plaintext",
        "KAFKA_CONSUMER_AUTH__SASL_USERNAME" => "username",
        "KAFKA_CONSUMER_AUTH__SASL_PASSWORD" => "password",
        "KAFKA_CONSUMER_AUTH__SASL_MECHANISM" => "PLAIN",

        "KAFKA_CONSUMER_KAFKA__SERVERS" => "server1:9092,server2:9092",

        "KAFKA_CONSUMER_CLIENT_ID" => "client-id"
      }
    }
    let(:config) { described_class.new }
    let(:kafka_config_defaults) do
      {
        "heartbeat.interval.ms": 5000,
        "reconnect.backoff.max.ms": 3000,
        "session.timeout.ms": 30000,
        "socket.connection.setup.timeout.ms": 5000,
        "socket.timeout.ms": 30000
      }
    end

    it "properly merges kafka options" do
      with_env(default_env) do
        expect(config.to_kafka_options)
          .to eq(kafka_config_defaults.merge(
            "bootstrap.servers": "server1:9092,server2:9092",
            "security.protocol": "sasl_plaintext",
            "sasl.mechanism": "PLAIN",
            "sasl.password": "password",
            "sasl.username": "username",
            # loaded from kafka_consumer.yml
            "allow.auto.create.topics": true
          ))
      end
    end

    it "has correct defaults" do
      with_env(default_env) do
        expect(config.deserializer_class).to eq("::Sbmt::KafkaConsumer::Serialization::NullDeserializer")
        expect(config.monitor_class).to eq("::Sbmt::KafkaConsumer::Instrumentation::SentryMonitor")
        expect(config.logger_class).to eq("::Sbmt::KafkaConsumer::Logger")
        expect(config.logger_listener_class).to eq("::Sbmt::KafkaConsumer::Instrumentation::LoggerListener")
        expect(config.metrics_listener_class).to eq("::Sbmt::KafkaConsumer::Instrumentation::YabedaMetricsListener")
      end
    end

    it "properly loads/maps consumer groups to config klasses" do
      with_env(default_env) do
        expect(config.consumer_groups)
          .to eq([
            Sbmt::KafkaConsumer::Config::ConsumerGroup.new(
              id: "group_id_1",
              name: "cg_with_single_topic",
              topics: [
                Sbmt::KafkaConsumer::Config::Topic.new(
                  name: "topic_with_inbox_items",
                  active: true,
                  manual_offset_management: true,
                  consumer: Sbmt::KafkaConsumer::Config::Consumer.new(
                    klass: "Sbmt::KafkaConsumer::InboxConsumer",
                    init_attrs: {
                      name: "test_items",
                      inbox_item: "TestInboxItem"
                    }
                  ),
                  deserializer: Sbmt::KafkaConsumer::Config::Deserializer.new(
                    klass: "Sbmt::KafkaConsumer::Serialization::NullDeserializer"
                  )
                )
              ]
            ),
            Sbmt::KafkaConsumer::Config::ConsumerGroup.new(
              id: "group_id_2",
              name: "cg_with_multiple_topics",
              topics: [
                Sbmt::KafkaConsumer::Config::Topic.new(
                  name: "topic_with_json_data",
                  active: true,
                  manual_offset_management: true,
                  consumer: Sbmt::KafkaConsumer::Config::Consumer.new(
                    klass: "Sbmt::KafkaConsumer::SimpleLoggingConsumer",
                    init_attrs: {
                      skip_on_error: true
                    }
                  ),
                  deserializer: Sbmt::KafkaConsumer::Config::Deserializer.new(
                    klass: "Sbmt::KafkaConsumer::Serialization::JsonDeserializer",
                    init_attrs: {
                      skip_decoding_error: true
                    }
                  )
                ),
                Sbmt::KafkaConsumer::Config::Topic.new(
                  name: "inactive_topic_with_autocommit",
                  active: false,
                  manual_offset_management: false,
                  consumer: Sbmt::KafkaConsumer::Config::Consumer.new(
                    klass: "Sbmt::KafkaConsumer::SimpleLoggingConsumer"
                  )
                ),
                Sbmt::KafkaConsumer::Config::Topic.new(
                  name: "topic_with_protobuf_data",
                  active: true,
                  manual_offset_management: true,
                  consumer: Sbmt::KafkaConsumer::Config::Consumer.new(
                    klass: "Sbmt::KafkaConsumer::SimpleLoggingConsumer"
                  ),
                  deserializer: Sbmt::KafkaConsumer::Config::Deserializer.new(
                    klass: "Sbmt::KafkaConsumer::Serialization::ProtobufDeserializer",
                    init_attrs: {
                      message_decoder_klass: "Sso::UserRegistration",
                      skip_decoding_error: true
                    }
                  )
                )
              ]
            )
          ])
      end
    end
  end
end
