# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Config::Probes do
  context "when no probes configured" do
    let(:config) { described_class.new }

    it "defaults to 9394 port and both endpoints enabled" do
      expect(config.port).to eq(9394)
      expect(config.endpoints).to eq(
        Sbmt::KafkaConsumer::Config::Probes::Endpoints.new(
          liveness: {
            enabled: true,
            path: "/liveness",
            timeout: 300
          },
          readiness: {
            enabled: true,
            path: "/readiness/kafka_consumer"
          }
        )
      )
    end
  end

  context "when something is configured" do
    let(:config) {
      described_class.new(
        port: 8080,
        endpoints: {
          liveness: {
            timeout: 15
          }
        }
      )
    }

    it "loads valid config" do
      expect(config.port).to eq(8080)
      expect(config.endpoints).to eq(
        Sbmt::KafkaConsumer::Config::Probes::Endpoints.new(
          liveness: {
            enabled: true,
            path: "/liveness",
            timeout: 15
          },
          readiness: {
            enabled: true,
            path: "/readiness/kafka_consumer"
          }
        )
      )
    end
  end
end
