# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::LoggerListener do
  let(:event) { double("event") }

  let(:message) { double("message") }
  let(:metadata) { OpenStruct.new(topic: "topic", partition: 0) }

  let(:inbox_name) { "inbox" }
  let(:event_name) { "event" }
  let(:status) { "status" }
  let(:message_uuid) { "uuid" }
  let(:time) { 10.20 }

  describe ".on_error_occurred" do
    it "logs error when consumer.base.consume_one event occurred" do
      expect(event).to receive(:[]).with(:error).and_return("some error")
      expect(event).to receive(:[]).with(:type).and_return("consumer.base.consume_one")
      expect(Rails.logger).to receive(:error)

      described_class.new.on_error_occurred(event)
    end

    it "logs error when consumer.inbox.consume_one event occurred" do
      expect(event).to receive(:[]).with(:error).and_return("some error")
      expect(event).to receive(:[]).with(:type).and_return("consumer.inbox.consume_one")
      expect(event).to receive(:[]).with(:status).and_return(status)
      expect(Rails.logger).to receive(:error)

      described_class.new.on_error_occurred(event)
    end
  end

  describe ".on_consumer_consumed_one" do
    it "logs info message" do
      expect(event).to receive(:payload).and_return(time: time)
      expect(Rails.logger).to receive(:info)

      described_class.new.on_consumer_consumed_one(event)
    end
  end

  describe ".on_consumer_inbox_consumed_one" do
    it "logs info message" do
      expect(event).to receive(:payload).and_return(time: time)
      expect(event).to receive(:[]).with(:status).and_return(status)
      expect(event).to receive(:[]).with(:message_uuid).and_return(message_uuid)
      expect(Rails.logger).to receive(:info)

      described_class.new.on_consumer_inbox_consumed_one(event)
    end
  end
end
