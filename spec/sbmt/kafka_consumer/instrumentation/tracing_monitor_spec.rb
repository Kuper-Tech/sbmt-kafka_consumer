# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::TracingMonitor do
  describe "when initialized" do
    it "returns sentry and otel monitors" do
      expect(described_class.new.monitors).to eq(
        [
          Sbmt::KafkaConsumer::Instrumentation::OpenTelemetryTracer,
          Sbmt::KafkaConsumer::Instrumentation::SentryTracer
        ]
      )
    end
  end
end
