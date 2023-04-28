# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Serialization::NullDeserializer do
  let(:message) { double("message") }
  let(:raw_message_body) { "body" }

  describe ".call" do
    it "returns raw_message" do
      expect(message).to receive(:raw_payload).and_return(raw_message_body)
      described_class.new.call(message) == raw_message_body
    end
  end
end
