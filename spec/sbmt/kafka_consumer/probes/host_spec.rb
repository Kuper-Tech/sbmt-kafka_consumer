# frozen_string_literal: true

require "rails_helper"
require "yabeda/prometheus/exporter"

RSpec.describe Sbmt::KafkaConsumer::Probes::Host do
  include Anyway::Testing::Helpers

  describe ".run_async" do
    let(:env) {
      {
        "KAFKA_CONSUMER_PROBES__PORT" => probes_port,
        "KAFKA_CONSUMER_METRICS__PORT" => metrics_port,
        "KAFKA_CONSUMER_METRICS__PATH" => metrics_path
      }.compact
    }
    let(:probes_port) { nil }
    let(:metrics_port) { nil }
    let(:metrics_path) { nil }

    before do
      allow(Thread).to receive(:new).and_yield
      allow(Rack::Handler::WEBrick).to receive(:run)
      allow_any_instance_of(Rack::Builder).to receive(:use)
      allow(HttpHealthCheck).to receive(:run_server_async)
      allow(Yabeda::Prometheus::Exporter).to receive(:new)
    end

    around do |ex|
      with_env(env) { ex.run }
    end

    context "when probe and metrics ports are equal" do
      let(:probes_port) { "8080" }
      let(:metrics_port) { "8080" }

      it "starts on single port" do
        expect(described_class).to receive(:start_on_single_port)
        described_class.run_async
      end

      it "calls WEBrick.run with the correct parameters" do
        described_class.run_async
        expect(Rack::Handler::WEBrick).to have_received(:run) do |rack_builder, **options|
          expect(options[:Host]).to eq "0.0.0.0"
          expect(options[:Port]).to eq 8080
          expect(rack_builder).to have_received(:use).with(Yabeda::Prometheus::Exporter, path: "/metrics")
        end
      end

      context "with custom metrics path" do
        let(:metrics_path) { "/custom_metrics_path" }

        it "calls WEBrick.run with the correct parameters" do
          described_class.run_async
          expect(Rack::Handler::WEBrick).to have_received(:run) do |rack_builder, **options|
            expect(options[:Host]).to eq "0.0.0.0"
            expect(options[:Port]).to eq 8080
            expect(rack_builder).to have_received(:use).with(Yabeda::Prometheus::Exporter, path: "/custom_metrics_path")
          end
        end
      end
    end

    context "when probe and metrics ports are different" do
      let(:probes_port) { "8080" }
      let(:metrics_port) { "9090" }

      it "starts on different ports" do
        expect(described_class).to receive(:start_on_different_ports)
        described_class.run_async
      end

      it "calls HttpHealthCheck.run_server_async with the correct parameters" do
        described_class.run_async
        expect(HttpHealthCheck).to have_received(:run_server_async).with(
          port: 8080,
          rack_app: an_instance_of(HttpHealthCheck::RackApp)
        )
      end

      it "calls WEBrick.run for metrics with the correct parameters" do
        described_class.run_async
        expect(Rack::Handler::WEBrick).to have_received(:run) do |rack_builder, **options|
          expect(options[:Host]).to eq "0.0.0.0"
          expect(options[:Port]).to eq 9090
          expect(rack_builder).to have_received(:use).with(Yabeda::Prometheus::Exporter, path: "/metrics")
        end
      end

      context "with custom metrics path" do
        let(:metrics_path) { "/custom_metrics_path" }

        it "calls WEBrick.run for metrics with the correct parameters" do
          described_class.run_async
          expect(Rack::Handler::WEBrick).to have_received(:run) do |rack_builder, **options|
            expect(options[:Host]).to eq "0.0.0.0"
            expect(options[:Port]).to eq 9090
            expect(rack_builder).to have_received(:use).with(Yabeda::Prometheus::Exporter, path: "/custom_metrics_path")
          end
        end
      end
    end
  end
end
