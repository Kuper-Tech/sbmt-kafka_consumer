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

  def expect_rack_v3_result_compatibility(res)
    expect(res[0]).to be_an(Integer)
    expect(res[0] >= 100).to be(true)

    expect(res[1]).to be_a(Hash)
    expect(res[1]).not_to be_frozen

    expect(res[2]).to be_a(Array)
    expect(res[2]).not_to be_frozen
  end

  describe ".call" do
    it "calls probe with env" do
      expect(service).to receive(:probe).with(env)
      service.call(env)
    end

    context "when there's an error" do
      before do
        allow(service).to receive(:probe).and_raise("Unexpected error")
      end

      it "returns 500" do
        expect(service.call(env)).to eq [
          500,
          {"Content-Type" => "application/json"},
          [{error_class: "RuntimeError", error_message: "Unexpected error"}.to_json]
        ]
      end

      it "returns Rack v3 compatible response" do
        expect_rack_v3_result_compatibility(service.call(env))
      end
    end

    describe ".probe_ok" do
      it "returns 200 with meta" do
        expect(service.probe_ok).to eq [200, {"Content-Type" => "application/json"}, ["{}"]]
      end

      it "returns Rack v3 compatible response" do
        expect_rack_v3_result_compatibility(service.probe_ok)
      end
    end

    describe ".probe_error" do
      let(:error_meta) { {foo: "bar"} }

      it "logs the error message and returns 500 with meta" do
        expect(service.probe_error(error_meta)).to eq [500, {"Content-Type" => "application/json"}, [error_meta.to_json]]
        expect(logger).to have_received(:error).with("probe error meta: #{error_meta.inspect}")
      end

      it "returns Rack v3 compatible response" do
        expect_rack_v3_result_compatibility(service.probe_error(error_meta))
      end
    end
  end
end
