# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::LivenessListener do
  subject(:probe) { service.call({}) }

  let(:service) { described_class.new }
  let(:consumer_group) { spy(:consumer_group, name: "CONSUMER_GROUP") }

  before do
    allow(Karafka::App).to receive(:routes).and_return([consumer_group])

    travel_to Time.now.utc # rubocop:disable Rails/TravelToWithoutBlock
  end

  context "without polls" do
    it "returns ok" do
      expect(probe).to eq [
        200,
        {"Content-Type" => "application/json"},
        [
          {
            timed_out_polls: false,
            errors_count: 0
          }.to_json
        ]
      ]
    end
  end

  context "with polls" do
    let(:subscription_group) { spy(:subscription_group, consumer_group: consumer_group) }
    let(:event) { spy(:event, payload: {subscription_group: subscription_group}) }

    before do
      service.on_connection_listener_fetch_loop(event)
    end

    it "returns ok" do
      expect(probe).to eq [
        200,
        {"Content-Type" => "application/json"},
        [
          {
            timed_out_polls: false,
            errors_count: 0
          }.to_json
        ]
      ]
    end

    context "with timed out polls" do
      before do
        service.on_connection_listener_fetch_loop(event)
        allow(service).to receive(:monotonic_now).and_wrap_original do |meth|
          meth.call + 315 * 1000
        end
      end

      it "returns error" do
        res = probe
        expect(res[0]).to eq 500
        expect(res[1]).to eq({"Content-Type" => "application/json"})
        expect(JSON.parse(res[2][0]).symbolize_keys).to match(
          a_hash_including(error_type: Sbmt::KafkaConsumer::Instrumentation::LivenessListener::ERROR_TYPE,
            timed_out_polls: true,
            errors_count: 0)
        )
      end
    end
  end

  context "with librdkafka errors" do
    let(:error_event) { {type: "librdkafka.error", error: StandardError.new("Test error")} }

    before do
      allow(error_event[:error]).to receive(:backtrace).and_return(["line 1", "line 2"])
    end

    it "increments error count and stores backtrace" do
      expect { service.on_error_occurred(error_event) }.to change { service.instance_variable_get(:@error_count) }.by(1)
      expect(service.instance_variable_get(:@error_backtrace)).to eq("line 1\nline 2")
    end

    context "when error count exceeds max_error_count" do
      before do
        10.times { service.on_error_occurred(error_event) }
      end

      it "returns error with error count and backtrace" do
        expect(probe).to eq [
          500,
          {"Content-Type" => "application/json"},
          [
            {
              error_type: Sbmt::KafkaConsumer::Instrumentation::LivenessListener::ERROR_TYPE,
              timed_out_polls: false,
              error_count: 10,
              error_backtrace: "line 1\nline 2"
            }.to_json
          ]
        ]
      end
    end
  end
end
