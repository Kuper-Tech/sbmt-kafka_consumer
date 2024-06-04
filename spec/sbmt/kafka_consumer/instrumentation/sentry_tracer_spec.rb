# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::SentryTracer do
  let(:sentry_transaction) { instance_double(Sentry::Transaction) }
  let(:trace_id) { "trace-id" }
  let(:caller) { double("consumer instance") }
  let(:message) { OpenStruct.new(topic: "topic", offset: 0, partition: 1, metadata: {topic: "topic"}, payload: "message payload") }
  let(:batch_messages) {
    [
      OpenStruct.new(topic: "topic", offset: 0, partition: 1, metadata: {topic: "topic"}, payload: "message payload"),
      OpenStruct.new(topic: "another_topic", offset: 1, partition: 2, metadata: {topic: "another_topic"}, payload: "another message payload")
    ]
  }
  let(:event_payload) { OpenStruct.new(caller: caller, message: message, trace_id: trace_id, type: nil) }
  let(:event_payload_with_batch) { OpenStruct.new(caller: caller, messages: batch_messages, trace_id: trace_id, type: nil) }

  before do
    allow(caller).to receive(:messages).and_return([message])
  end

  describe ".trace" do
    context "when sentry is not initialized" do
      it "does nothing" do
        expect(Sentry).to receive(:initialized?).and_return(false)
        expect(Sentry).not_to receive(:start_transaction)

        described_class.new("consumer.consumed_one", event_payload).trace {}
      end
    end

    context "when event is consumer.consumed_one" do
      before { allow(Sentry).to receive(:initialized?).and_return(true) }

      it "traces message" do
        expect(Sentry).to receive(:get_current_scope).and_return(Sentry::Scope.new)
        expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)

        expect(sentry_transaction).to receive(:is_a?).and_return(Sentry::Span)
        expect(sentry_transaction).to receive(:set_http_status).with(200)
        expect(sentry_transaction).to receive(:finish)

        described_class.new("consumer.consumed_one", event_payload).trace {}
      end

      context "with scope" do
        let(:sentry_scope) { instance_double(Sentry::Scope) }

        before do
          allow(sentry_scope).to receive(:transaction_name)
          allow(sentry_scope).to receive(:set_span)
          allow(sentry_scope).to receive(:clear)
          allow(sentry_transaction).to receive(:set_http_status)
          allow(sentry_transaction).to receive(:finish)
        end

        context "when custom consumer class is used" do
          let(:custom_class) { stub_const("SomeModule::CustomConsumerClass", Class.new(Sbmt::KafkaConsumer::BaseConsumer)) }
          let(:caller) { custom_class.consumer_klass.new }

          it "sets proper params" do
            expect(Sentry).to receive(:get_current_scope).and_return(sentry_scope)
            expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)

            expect(sentry_scope).to receive(:set_transaction_name).with("Sbmt/KafkaConsumer/SomeModule::CustomConsumerClass")
            expect(sentry_scope).to receive(:set_tags).with(hash_including(offset: 0, topic: "topic", trace_id: "trace-id"))

            described_class.new("consumer.consumed_one", event_payload).trace {}
          end
        end

        context "when base consumer class is used" do
          let(:caller) { Sbmt::KafkaConsumer::BaseConsumer.consumer_klass.new }

          it "sets proper params" do
            expect(Sentry).to receive(:get_current_scope).and_return(sentry_scope)
            expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)

            expect(sentry_scope).to receive(:set_transaction_name).with("Sbmt/KafkaConsumer/Sbmt::KafkaConsumer::BaseConsumer")
            expect(sentry_scope).to receive(:set_tags).with(hash_including(offset: 0, topic: "topic", trace_id: "trace-id"))

            described_class.new("consumer.consumed_one", event_payload).trace {}
          end
        end
      end

      it "traces message when error is raised" do
        expect(Sentry).to receive(:get_current_scope).and_return(Sentry::Scope.new)
        expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)

        expect(sentry_transaction).to receive(:is_a?).and_return(Sentry::Span)
        expect(sentry_transaction).to receive(:set_http_status).with(500)
        expect(sentry_transaction).to receive(:finish)

        expect do
          described_class.new("consumer.consumed_one", event_payload).trace { raise "error" }
        end.to raise_error("error")
      end
    end

    context "when event is consumer.consumed_batch" do
      before { allow(Sentry).to receive(:initialized?).and_return(true) }

      it "traces message" do
        expect(Sentry).to receive(:get_current_scope).and_return(Sentry::Scope.new)
        expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)

        expect(sentry_transaction).to receive(:is_a?).and_return(Sentry::Span)
        expect(sentry_transaction).to receive(:set_http_status).with(200)
        expect(sentry_transaction).to receive(:finish)

        described_class.new("consumer.consumed_batch", event_payload_with_batch).trace {}
      end

      context "with scope" do
        let(:sentry_scope) { instance_double(Sentry::Scope) }

        before do
          allow(sentry_scope).to receive(:transaction_name)
          allow(sentry_scope).to receive(:set_span)
          allow(sentry_scope).to receive(:clear)
          allow(sentry_transaction).to receive(:set_http_status)
          allow(sentry_transaction).to receive(:finish)
        end

        context "when custom consumer class is used" do
          let(:custom_class) { stub_const("SomeModule::CustomConsumerClass", Class.new(Sbmt::KafkaConsumer::BaseConsumer)) }
          let(:caller) { custom_class.consumer_klass.new }

          it "sets proper params" do
            expect(Sentry).to receive(:get_current_scope).and_return(sentry_scope)
            expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)

            expect(sentry_scope).to receive(:set_transaction_name).with("Sbmt/KafkaConsumer/SomeModule::CustomConsumerClass")
            expect(sentry_scope).to receive(:set_tags).with(hash_including(first_offset: 0, last_offset: 1, topic: "topic", trace_id: "trace-id"))

            described_class.new("consumer.consumed_batch", event_payload_with_batch).trace {}
          end
        end

        context "when base consumer class is used" do
          let(:caller) { Sbmt::KafkaConsumer::BaseConsumer.consumer_klass.new }

          it "sets proper params" do
            expect(Sentry).to receive(:get_current_scope).and_return(sentry_scope)
            expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)

            expect(sentry_scope).to receive(:set_transaction_name).with("Sbmt/KafkaConsumer/Sbmt::KafkaConsumer::BaseConsumer")
            expect(sentry_scope).to receive(:set_tags).with(hash_including(first_offset: 0, last_offset: 1, topic: "topic", trace_id: "trace-id"))

            described_class.new("consumer.consumed_batch", event_payload_with_batch).trace {}
          end
        end
      end

      it "traces message when error is raised" do
        expect(Sentry).to receive(:get_current_scope).and_return(Sentry::Scope.new)
        expect(Sentry).to receive(:start_transaction).and_return(sentry_transaction)

        expect(sentry_transaction).to receive(:is_a?).and_return(Sentry::Span)
        expect(sentry_transaction).to receive(:set_http_status).with(500)
        expect(sentry_transaction).to receive(:finish)

        expect do
          described_class.new("consumer.consumed_batch", event_payload_with_batch).trace { raise "error" }
        end.to raise_error("error")
      end
    end

    context "when event is error.occurred" do
      let(:ex) { StandardError.new("error") }
      let(:sentry_scope) { double("sentry scope") }
      let(:event_payload) { OpenStruct.new(caller: caller, message: message, trace_id: trace_id, error: ex, type: nil) }

      before do
        allow(Sentry).to receive(:initialized?).and_return(true)
        allow(Sentry).to receive(:with_scope).and_yield(sentry_scope)
      end

      context "when detailed logging is not enabled" do
        it "does not report payload" do
          expect(Sentry).to receive(:capture_exception).with(ex)
          expect(sentry_scope).not_to receive(:set_contexts)

          described_class.new("error.occurred", event_payload).trace {}
        end
      end

      context "when detailed logging is enabled" do
        let(:event_payload) { OpenStruct.new(caller: caller, message: message, trace_id: trace_id, error: ex, type: "consumer.inbox.consume_one") }

        it "captures exception" do
          expect(Sentry).to receive(:capture_exception).with(ex)
          expect(caller).to receive(:log_payload?).and_return(true)
          expect(sentry_scope).to receive(:set_contexts).with(contexts: {
            payload: message.payload,
            metadata: message.metadata
          })

          described_class.new("error.occurred", event_payload).trace {}
        end
      end

      context "when event is not an exception" do
        let(:ex) { "some string" }

        it "does not capture exception" do
          expect(Sentry).not_to receive(:capture_exception)

          described_class.new("error.occurred", event_payload).trace {}
        end
      end
    end
  end
end
