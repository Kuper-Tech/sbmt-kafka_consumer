# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::LoggerListener do
  let(:metadata) { OpenStruct.new(topic: "topic", partition: 0, key: "key", offset: 42) }
  let(:message) { double("message", metadata: metadata) }
  let(:caller) { double(topic: double(consumer_group: double(id: "group_id"))) }
  let(:event) { double("event", payload: {message: message, time: time, caller: caller}) }

  let(:inbox_name) { "inbox" }
  let(:event_name) { "event" }
  let(:status) { "status" }
  let(:message_uuid) { "uuid" }
  let(:time) { 10.20 }
  let(:logger) { double("Logger") }
  let(:error) { StandardError.new("some error") }
  let(:error_message) { "some error message" }

  before do
    allow(Sbmt::KafkaConsumer).to receive(:logger).and_return(logger)

    allow_any_instance_of(described_class).to receive(:log_backtrace).and_return("some backtrace")
    allow_any_instance_of(described_class).to receive(:error_message).and_return(error_message)
  end

  describe ".on_error_occurred" do
    it "logs error when consumer.base.consume_one event occurred" do
      allow(event).to receive(:[]).with(:error).and_return(error)
      allow(event).to receive(:[]).with(:type).and_return("consumer.base.consume_one")
      allow(event).to receive(:[]).with(:log_level).and_return(:error)

      expect(logger).to receive(:tagged).with(hash_including(
        type: "consumer.base.consume_one",
        stacktrace: "some backtrace"
      )).and_yield

      expect(logger).to receive(:error).with(error_message)

      described_class.new.on_error_occurred(event)
    end

    it "logs error when consumer.inbox.consume_one event occurred" do
      allow(event).to receive(:[]).with(:error).and_return(error)
      allow(event).to receive(:[]).with(:type).and_return("consumer.inbox.consume_one")
      allow(event).to receive(:[]).with(:status).and_return(status)
      allow(event).to receive(:[]).with(:log_level).and_return(:error)

      expect(logger).to receive(:tagged).with(hash_including(
        type: "consumer.inbox.consume_one",
        status: "status",
        stacktrace: "some backtrace"
      )).and_yield

      expect(logger).to receive(:error).with(error_message)

      described_class.new.on_error_occurred(event)
    end

    it "logs warnings" do
      allow(event).to receive(:[]).with(:error).and_return("test error")
      allow(event).to receive(:[]).with(:type).and_return("consumer.base.consume_one")
      allow(event).to receive(:[]).with(:log_level).and_return(:warn)

      expect(logger).to receive(:tagged).with(hash_including(
        type: "consumer.base.consume_one",
        stacktrace: "some backtrace"
      )).and_yield

      expect(logger).to receive(:warn).with(error_message)

      described_class.new.on_error_occurred(event)
    end
  end

  describe ".on_consumer_consumed_one" do
    it "logs info message" do
      expect(logger).to receive(:tagged).with(hash_including(
        kafka: hash_including(
          topic: "topic",
          partition: 0,
          key: "key",
          offset: 42,
          consumer_group: "group_id",
          consume_duration_ms: time
        )
      )).and_yield

      expect(logger).to receive(:info).with("Successfully consumed message")

      described_class.new.on_consumer_consumed_one(event)
    end
  end

  describe ".on_consumer_inbox_consumed_one" do
    it "logs info message" do
      expect(event).to receive(:[]).with(:status).and_return(status)
      expect(event).to receive(:[]).with(:message_uuid).and_return(message_uuid)

      expect(logger).to receive(:tagged).with(hash_including(
        kafka: hash_including(
          topic: "topic",
          partition: 0,
          key: "key",
          offset: 42,
          consumer_group: "group_id",
          consume_duration_ms: time
        )
      )).and_yield

      expect(logger).to receive(:info).with("Successfully consumed message with uuid: uuid")

      described_class.new.on_consumer_inbox_consumed_one(event)
    end
  end
end
