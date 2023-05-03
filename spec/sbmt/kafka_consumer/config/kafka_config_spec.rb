# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Config::Kafka, type: :config do
  let(:config) { described_class.new }

  context "with servers validation" do
    it "raises error if servers are not set" do
      expect { config }.to raise_error(/are missing or empty: servers/)
    end

    it "raises error if servers have unexpected format" do
      with_env(
        "KAFKA_CONSUMER_KAFKA_SERVERS" => "kafka://server:9092"
      ) do
        expect { config }.to raise_error(/invalid servers:/)
      end
    end
  end

  context "when servers are properly set" do
    let(:servers) { "server1:9092,server2:9092" }

    it "successfully loads config and translates to rdkafka options" do
      with_env(
        "KAFKA_CONSUMER_KAFKA_SERVERS" => servers
      ) do
        expect(config.servers).to eq(servers)
        expect(config.to_rdkafka_options)
          .to eq("bootstrap.servers": servers)
      end
    end
  end

  context "when servers are also set in rdkafka options" do
    let(:root_servers) { "server1:9092,server2:9092" }
    let(:rdkafka_servers) { "server3:9092,server4:9092" }

    it "root servers option takes precedence over rdkafka config" do
      with_env(
        "KAFKA_CONSUMER_KAFKA_SERVERS" => root_servers,
        "KAFKA_CONSUMER_KAFKA_RDKAFKA_BOOTSTRAP_SERVERS" => rdkafka_servers
      ) do
        expect(config.servers).to eq(root_servers)
        expect(config.to_rdkafka_options)
          .to eq("bootstrap.servers": root_servers)
      end
    end
  end
end
