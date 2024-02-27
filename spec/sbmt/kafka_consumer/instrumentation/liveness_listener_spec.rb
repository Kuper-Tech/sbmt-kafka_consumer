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
    it "returns error" do
      expect(probe).to eq [
        500,
        {"Content-Type" => "application/json"},
        [{failed_groups: {"CONSUMER_GROUP" => {had_poll: false}}}.to_json]
      ]
    end
  end

  context "with polls" do
    let(:subscription_group) { spy(:subscription_group, consumer_group: consumer_group) }
    let(:event) { spy(:event, payload: {subscription_group: subscription_group}) }

    before do
      service.on_connection_listener_fetch_loop(event)
      travel 1.second
    end

    it "returns ok" do
      expect(probe).to eq [
        200,
        {"Content-Type" => "application/json"},
        [
          {
            groups: {
              "CONSUMER_GROUP" => {
                had_poll: true,
                last_poll_at: 1.second.ago.utc,
                seconds_since_last_poll: 1
              }
            }
          }.to_json
        ]
      ]
    end

    context "with timed out polls" do
      before do
        service.on_connection_listener_fetch_loop(event)
        travel 15.seconds
      end

      it "returns error" do
        expect(probe).to eq [
          500,
          {"Content-Type" => "application/json"},
          [
            {
              failed_groups: {
                "CONSUMER_GROUP" => {
                  had_poll: true,
                  last_poll_at: 15.seconds.ago.utc,
                  seconds_since_last_poll: 15
                }
              }
            }.to_json
          ]
        ]
      end
    end
  end
end
