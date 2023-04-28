# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::BaseListener do
  let(:event) { double("event") }
  let(:payload) { double("payload") }

  describe ".consumer_tags" do
    let(:message) { double("message") }
    let(:metadata) { OpenStruct.new(topic: "topic", partition: 0) }

    it "returns consumer tags" do
      expect(event).to receive(:[]).with(:message).and_return(message)
      expect(message).to receive(:metadata).and_return(metadata).twice

      expect(described_class.new.send(:consumer_tags, event)).to eq({topic: "topic", partition: 0})
    end
  end

  describe ".inbox_tags" do
    let(:inbox_name) { "inbox" }
    let(:event_name) { "event" }
    let(:status) { "status" }

    it "returns tags" do
      expect(event).to receive(:[]).with(:inbox_name).and_return(inbox_name)
      expect(event).to receive(:[]).with(:event_name).and_return(event_name)
      expect(event).to receive(:[]).with(:status).and_return(status)

      expect(described_class.new.send(:inbox_tags, event))
        .to eq(
          {
            inbox_name: inbox_name,
            event_name: event_name,
            status: status
          }
        )
    end
  end

  describe ".error_message" do
    it "builds correct message when exception provided" do
      expect(described_class.new.send(:error_message, StandardError.new("test")))
        .to eq("test")
    end

    it "builds correct message when dry-result provided" do
      expect(described_class.new.send(:error_message, Dry::Monads::Result::Failure.new("test")))
        .to eq("test")
    end

    it "builds correct message when regular string provided" do
      expect(described_class.new.send(:error_message, "test"))
        .to eq("test")
    end
  end

  describe ".log_backtrace" do
    let(:error) { double("argument") }

    it "logs backtrace when exception provided" do
      expect(error).to receive(:backtrace).and_return(["backtrace1", "backtrace2"])
      expect(Rails.logger).to receive(:error).with("backtrace1\nbacktrace2")

      described_class.new.send(:log_backtrace, error)
    end

    it "logs backtrace when dry-result provided" do
      expect(error).to receive(:trace).and_return("trace")
      expect(Rails.logger).to receive(:error).with("trace")

      described_class.new.send(:log_backtrace, error)
    end
  end
end
