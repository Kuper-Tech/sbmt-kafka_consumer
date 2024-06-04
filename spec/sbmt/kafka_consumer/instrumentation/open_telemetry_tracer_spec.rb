# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::OpenTelemetryTracer do
  let(:topic_name) { "topic" }
  let(:message) { OpenStruct.new(topic: topic_name, offset: 0, partition: 1, metadata: {topic: topic_name}, payload: "message payload") }
  let(:batch_messages) {
    [
      OpenStruct.new(topic: "topic", offset: 0, partition: 1, metadata: {topic: "topic"}, payload: "message payload"),
      OpenStruct.new(topic: "another_topic", offset: 1, partition: 2, metadata: {topic: "another_topic"}, payload: "another message payload")
    ]
  }
  let(:consumer_group_name) { "consumer-group-name" }
  let(:consumer_group) { OpenStruct.new(id: consumer_group_name) }
  let(:consumer_topic) { OpenStruct.new(consumer_group: consumer_group) }
  let(:consumer) { OpenStruct.new(topic: consumer_topic, inbox_name: "inbox/name", event_name: nil) }
  let(:event_payload) { OpenStruct.new(caller: consumer, message: message, inbox_name: "inbox/name", event_name: nil, status: "failure") }
  let(:event_payload_with_batch) { OpenStruct.new(caller: consumer, messages: batch_messages, inbox_name: "inbox/name", event_name: nil, status: "failure") }

  describe "when disabled" do
    before { described_class.enabled = false }

    it "does not trace consumed message" do
      expect(::Sbmt::KafkaConsumer::Instrumentation::OpenTelemetryLoader).not_to receive(:instance)

      described_class.new("consumer.consumed_one", event_payload).trace {}
    end
  end

  describe ".trace" do
    let(:tracer) { double("tracer") }
    let(:instrumentation_instance) { double("instrumentation instance") }

    before do
      described_class.enabled = true

      allow(::Sbmt::KafkaConsumer::Instrumentation::OpenTelemetryLoader).to receive(:instance).and_return(instrumentation_instance)
      allow(instrumentation_instance).to receive(:tracer).and_return(tracer)
    end

    it "traces message" do
      expect(tracer).to receive(:in_span).with("consume topic", links: nil, kind: :consumer, attributes: {
        "messaging.destination" => topic_name,
        "messaging.destination_kind" => "topic",
        "messaging.kafka.consumer_group" => consumer_group_name,
        "messaging.kafka.offset" => 0,
        "messaging.kafka.partition" => 1,
        "messaging.system" => "kafka"
      })
      described_class.new("consumer.consumed_one", event_payload).trace {}
    end

    it "traces messages" do
      expect(tracer).to receive(:in_span).with("consume batch", links: [], kind: :consumer, attributes: {
        "messaging.destination" => topic_name,
        "messaging.destination_kind" => "topic",
        "messaging.kafka.consumer_group" => consumer_group_name,
        "messaging.system" => "kafka",
        "messaging.batch_size" => 2,
        "messaging.first_offset" => 0,
        "messaging.last_offset" => 1
      })
      described_class.new("consumer.consumed_batch", event_payload_with_batch).trace {}
    end

    it "traces inbox message" do
      expect(tracer).to receive(:in_span).with("inbox inbox/name process", kind: :consumer, attributes: {
        "inbox.inbox_name" => "inbox/name",
        "inbox.status" => "failure"
      })
      described_class.new("consumer.inbox.consumed_one", event_payload).trace {}
    end
  end
end
