# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::SentryMonitor do
  let(:payload) { double("payload") }
  let(:message) { OpenStruct.new(topic: "topic", offset: 0, metadata: {topic: "topic"}, payload: "message payload") }
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

    context "when event is error.occurred" do
      let(:caller) { double("consumer instance") }
      let(:sentry_scope) { double("sentry scope") }

      before do
        allow(caller).to receive(:messages).and_return([message])
        allow(Sentry).to receive(:initialized?).and_return(true)
        allow(Sentry).to receive(:with_scope).and_yield(sentry_scope)
        allow(payload).to receive(:[]).with(:message).and_return(message)
        allow(payload).to receive(:[]).with(:type).and_return("consumer.base.consume_one")
      end

      it "traces event without log_payload? enabled" do
        ex = StandardError.new("error")

        expect(Sentry).to receive(:capture_exception).with(ex)
        allow(payload).to receive(:[]).with(:error).and_return(ex)
        allow(payload).to receive(:[]).with(:caller).and_return(caller)
        allow(caller).to receive(:log_payload?).and_return(false)

        described_class.new.send(:trace, "error.occurred", payload) {}
      end

      it "traces event if caller is nil" do
        ex = StandardError.new("error")

        expect(Sentry).to receive(:capture_exception).with(ex)
        expect(payload).to receive(:[]).with(:caller).and_return(nil)
        expect(payload).to receive(:[]).with(:type).and_return(nil)
        allow(payload).to receive(:[]).with(:error).and_return(ex)

        described_class.new.send(:trace, "error.occurred", payload) {}
      end

      it "traces event with log_payload? enabled" do
        ex = StandardError.new("error")

        expect(Sentry).to receive(:capture_exception).with(ex)
        expect(sentry_scope).to receive(:set_contexts).with(contexts: {
          payload: message.payload,
          metadata: message.metadata
        })
        allow(payload).to receive(:[]).with(:error).and_return(ex)
        allow(payload).to receive(:[]).with(:caller).and_return(caller)
        allow(caller).to receive(:log_payload?).and_return(true)

        described_class.new.send(:trace, "error.occurred", payload) {}
      end

      it "does not trace error.occurred event if event is not an exception" do
        expect(Sentry).not_to receive(:capture_exception)
        allow(payload).to receive(:[]).with(:error).and_return("error")

        described_class.new.send(:trace, "error.occurred", payload) {}
      end
    end
  end
end
