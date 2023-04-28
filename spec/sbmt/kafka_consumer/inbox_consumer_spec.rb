# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::InboxConsumer do
  include_context "with sbmt karafka consumer"

  let(:klass) do
    described_class[
      name: "test_items",
      inbox_item: "TestInboxItem"
    ]
  end

  let(:consumer) { build_consumer(klass.new) }
  let(:create_item_result) { Dry::Monads::Result::Success }
  let(:logger) { double(ActiveSupport::TaggedLogging) }
  let(:uuid) { "test-uuid-1" }

  before do
    publish_to_sbmt_karafka(
      '{"test":"message"}',
      key: "test-key",
      partition: 10,
      headers: {
        "Idempotency-Key" => uuid,
        "Dispatched-At" => 5.seconds.ago,
        "Sequence-ID" => 3
      }
    )
  end

  after do
    described_class.send :remove_const, "TestItemConsumer"
  end

  context "when message valid" do
    it "creates inbox item" do
      expect(kafka_client).to receive(:mark_as_consumed!)
      expect(Rails.logger).to receive(:info).with(/Successfully consumed/).twice
      expect { consume_with_sbmt_karafka }
        .to change(TestInboxItem, :count).by(1)
        .and increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: nil,
          status: "success"
        )
    end

    context "with additional metrics after consume" do
      let(:inbox_item) { build(:inbox_item) }

      before do
        allow(Sbmt::Outbox::CreateInboxItem).to receive(:call).and_return(Dry::Monads::Result::Success.new(inbox_item))
      end

      it "call method" do
        expect(inbox_item).to receive(:track_metrics_after_consume)
        consume_with_sbmt_karafka
      end
    end
  end

  context "when got failure from inbox item creator" do
    before do
      allow(Sbmt::Outbox::CreateInboxItem).to receive(:call)
        .and_return(Dry::Monads::Result::Failure.new("test failure"))
    end

    it "let consumer crash without committing offsets" do
      expect(kafka_client).not_to receive(:mark_as_consumed!)
      expect(Rails.logger).to receive(:error).exactly(4).times
      expect {
        consume_with_sbmt_karafka
      }.to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: nil,
          status: "failure"
        )
    end
  end

  context "when got exception from inbox item creator" do
    before do
      allow(Sbmt::Outbox::CreateInboxItem).to receive(:call)
        .and_raise("test exception")
    end

    it "let consumer crash without committing offsets" do
      expect(kafka_client).not_to receive(:mark_as_consumed!)
      expect(Rails.logger).to receive(:error).exactly(4).times
      expect {
        consume_with_sbmt_karafka
      }.to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: nil,
          status: "failure"
        )
    end
  end

  context "when message idempotency header does not exist" do
    before do
      stub_const("Sbmt::KafkaConsumer::InboxConsumer::IDEMPOTENCY_HEADER_NAME", "non-existent-header")
    end

    it "let consumer crash without committing offsets" do
      expect(kafka_client).to receive(:mark_as_consumed!)
      expect(Rails.logger).to receive(:info).with(/Successfully consumed/).twice
      expect { consume_with_sbmt_karafka }
        .to change(TestInboxItem, :count).by(1)
        .and increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: nil,
          status: "success"
        )
    end
  end

  context "when there is the same inbox item exists" do
    before do
      create(:inbox_item, uuid: uuid)
    end

    it "skips creating a new one" do
      expect(kafka_client).to receive(:mark_as_consumed!)
      expect(Rails.logger).to receive(:error)
      expect { consume_with_sbmt_karafka }
        .to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: nil,
          status: "duplicate"
        )
        .and not_change(TestInboxItem, :count)
    end
  end
end
