# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::SentryMonitor do
  let(:payload) { double("payload") }
  let(:message) { OpenStruct.new(topic: "topic", offset: 0) }
  let(:sentry_transaction) { instance_double(Sentry::Transaction) }

  describe ".trace" do
    it "does nothing if sentry is not initialized" do
      expect(Sentry).to receive(:initialized?).and_return(false)

      described_class.new.send(:trace, "event_id", payload) {}
    end

    it "traces consumer.consumed_one event when successful" do
      expect(Sentry).to receive(:initialized?).and_return(true)
      expect(Sentry).to receive(:get_current_scope).and_return(Sentry::Scope.new)
      expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)
      expect(payload).to receive(:[]).with(:message).and_return(message)
      expect(payload).to receive(:[]).with(:trace_id).and_return("trace_id")

      expect(sentry_transaction).to receive(:is_a?).and_return(Sentry::Span)
      expect(sentry_transaction).to receive(:set_http_status).with(200)
      expect(sentry_transaction).to receive(:finish)

      described_class.new.send(:trace, "consumer.consumed_one", payload) {}
    end

    it "traces consumer.consumed_one event when error is raised" do
      expect(Sentry).to receive(:initialized?).and_return(true)
      expect(Sentry).to receive(:get_current_scope).and_return(Sentry::Scope.new)
      expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)
      expect(payload).to receive(:[]).with(:message).and_return(message)
      expect(payload).to receive(:[]).with(:trace_id).and_return("trace_id")

      expect(sentry_transaction).to receive(:is_a?).and_return(Sentry::Span)
      expect(sentry_transaction).to receive(:set_http_status).with(500)
      expect(sentry_transaction).to receive(:finish)

      expect do
        described_class.new.send(:trace, "consumer.consumed_one", payload) { raise "error" }
      end.to raise_error("error")
    end

    it "traces error.occurred event" do
      expect(Sentry).to receive(:initialized?).and_return(true)
      expect(Sentry).to receive(:capture_exception).with("error")
      expect(payload).to receive(:[]).with(:error).and_return("error")

      described_class.new.send(:trace, "error.occurred", payload) {}
    end
  end
end
