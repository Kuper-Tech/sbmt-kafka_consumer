# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Config::Kafka, type: :config do
  let(:kafka_config_defaults) do
    {
      "heartbeat.interval.ms": 5000,
      "reconnect.backoff.max.ms": 3000,
      "session.timeout.ms": 30000,
      "socket.connection.setup.timeout.ms": 5000,
      "socket.timeout.ms": 30000
    }
  end

  context "with servers validation" do
    it "raises error if servers are not set" do
      expect { described_class.new }
        .to raise_error(/:servers is missing/)
    end

    it "raises error if servers have unexpected format" do
      expect { described_class.new(servers: "kafka://server:9092") }
        .to raise_error(/violates constraints/)
    end
  end

  context "when servers are properly set" do
    let(:servers) { "server1:9092,server2:9092" }
    let(:config) { described_class.new(servers: servers) }

    it "successfully loads config and translates to kafka options" do
      expect(config.servers).to eq(servers)
      expect(config.to_kafka_options)
        .to eq(kafka_config_defaults.merge("bootstrap.servers": servers))
    end
  end

  context "when servers are also set in kafka options" do
    let(:root_servers) { "server1:9092,server2:9092" }
    let(:kafka_servers) { "server3:9092,server4:9092" }
    let(:config) { described_class.new(servers: root_servers, kafka_options: {"bootstrap.servers": kafka_servers}) }

    it "root servers option takes precedence over kafka config" do
      expect(config.servers).to eq(root_servers)
      expect(config.to_kafka_options)
        .to eq(kafka_config_defaults.merge("bootstrap.servers": root_servers))
    end
  end
end
