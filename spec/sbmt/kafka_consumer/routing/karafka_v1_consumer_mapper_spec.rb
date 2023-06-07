# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Routing::KarafkaV1ConsumerMapper do
  describe ".call" do
    it "underscores client-id in consumer-group name" do
      # client_id is "some-name" in kafka_consumer.yml
      expect(described_class.new.call("consumer-group"))
        .to eq("some_name_consumer-group")
    end
  end
end
