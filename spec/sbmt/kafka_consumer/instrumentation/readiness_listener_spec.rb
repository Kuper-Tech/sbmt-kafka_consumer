# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::ReadinessListener do
  subject(:probe) { service.call({}) }

  let(:service) { described_class.new }
  let(:headers) { {"Content-Type" => "application/json"} }
  let(:error_response) { [500, headers, [{ready: false}.to_json]] }
  let(:ok_response) { [200, headers, [{ready: true}.to_json]] }

  shared_examples "error responder" do
    it "returns error" do
      expect(probe).to eq error_response
    end
  end

  context "without any events" do
    it_behaves_like "error responder"
  end

  context "with app.stopping event" do
    before do
      service.on_app_running({})
      service.on_app_stopping({})
    end

    it_behaves_like "error responder"
  end

  context "with app.running event" do
    before { service.on_app_running({}) }

    it "returns ok" do
      expect(probe).to eq ok_response
    end
  end
end
