# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Config::Metrics do
  context "when no probes configured" do
    let(:config) { described_class.new }

    it "has default values" do
      expect(config.port).to be_nil
      expect(config.path).to eq("/metrics")
    end
  end

  context "when something is configured" do
    let(:config) {
      described_class.new(
        port: 8080,
        path: "/custom_metrics"
      )
    }

    it "loads valid config" do
      expect(config.port).to eq(8080)
      expect(config.path).to eq("/custom_metrics")
    end
  end
end
