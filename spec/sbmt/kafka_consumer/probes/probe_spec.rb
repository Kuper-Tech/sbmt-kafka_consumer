# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Probes::Probe do
  let(:subject_klass) do
    Class.new do
      include Sbmt::KafkaConsumer::Probes::Probe

      def probe(_env); end
    end
  end

  let(:env) { double(:env) }
  let(:service) { subject_klass.new }

  describe ".call" do
    it "calls probe with env" do
      expect(service).to receive(:probe).with(env)
      service.call(env)
    end

    it "returns 500 when there's an error" do
      allow(service).to receive(:probe).and_raise("Unexpected error")
      expect(service.call(env)).to eq [
        500,
        {"Content-Type" => "application/json"},
        [{error_class: "RuntimeError", error_message: "Unexpected error"}.to_json]
      ]
    end

    describe ".probe_ok" do
      it "returns 200 with meta" do
        expect(service.probe_ok).to eq [200, {"Content-Type" => "application/json"}, ["{}"]]
      end
    end

    describe ".probe_error" do
      it "returns 500 with meta" do
        expect(service.probe_error).to eq [500, {"Content-Type" => "application/json"}, ["{}"]]
      end
    end
  end
end
