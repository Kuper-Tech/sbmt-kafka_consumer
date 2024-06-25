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
  let(:logger) { instance_double(Logger) }

  before do
    allow(Sbmt::KafkaConsumer).to receive(:logger).and_return(logger)
    allow(logger).to receive(:error)
  end

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
      it "logs the error message and returns 500 with meta" do
        error_meta = {foo: "bar"}
        expect(service.probe_error(error_meta)).to eq [500, {"Content-Type" => "application/json"}, [error_meta.to_json]]

        expect(logger).to have_received(:error).with("probe error meta: #{error_meta.inspect}")
      end
    end
  end
end
