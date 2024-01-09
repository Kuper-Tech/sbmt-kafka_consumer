# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::InboxConsumer do
  include_context "with sbmt karafka consumer"

  let(:klass) do
    described_class.consumer_klass(
      name: "test_items",
      event_name: "test-event-name",
      inbox_item: "TestInboxItem",
      skip_on_error: skip_on_error,
      outbox_producer: outbox_producer
    )
  end

  let(:skip_on_error) { false }
  let(:outbox_producer) { true }
  let(:consumer) { build_consumer(klass.new) }
  let(:create_item_result) { Dry::Monads::Result::Success }
  let(:logger) { double(ActiveSupport::TaggedLogging) }
  let(:uuid) { "test-uuid-1" }
  let(:message_key) { "test-key" }
  let(:message_offset) { 0 }
  let(:headers) do
    {
      "Idempotency-Key" => uuid,
      "Dispatched-At" => 5.seconds.ago,
      "Sequence-ID" => 3
    }
  end

  before do
    publish_to_sbmt_karafka(
      '{"test":"message"}',
      offset: message_offset,
      key: message_key,
      partition: 10,
      headers: headers
    )
  end

  after do
    # clearing of constants set in the`Sbmt::KafkaConsumer::InboxConsumer.consumer_klass` method
    described_class.send :remove_const, "TestItemConsumer" # rubocop:disable RSpec/RemoveConst
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
          event_name: "test-event-name",
          status: "success"
        )
      expect(TestInboxItem.last.options)
        .to include(
          {
            group_id: "some_name_test_group",
            partition: 10,
            source: "KAFKA",
            topic: "test_topic"
          }
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

    context "when skip_on_error is enabled" do
      let(:skip_on_error) { true }

      it "skips failed message and continues processing" do
        expect(kafka_client).not_to receive(:mark_as_consumed!)
        allow(Rails.logger).to receive(:warn)
        expect {
          consume_with_sbmt_karafka
        }.to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
          .with_tags(
            inbox_name: "test_inbox_item",
            event_name: "test-event-name",
            status: "skipped"
          )
      end

      context "when got active record error" do
        before do
          allow(Sbmt::Outbox::CreateInboxItem)
            .to receive(:call).and_raise(ActiveRecord::StatementInvalid)
        end

        it "skips failed message and continues processing" do
          expect(kafka_client).not_to receive(:mark_as_consumed!)
          allow(Rails.logger).to receive(:warn)
          expect {
            consume_with_sbmt_karafka
          }.to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
            .with_tags(
              inbox_name: "test_inbox_item",
              event_name: "test-event-name",
              status: "skipped"
            )
        end
      end
    end

    context "when skip_on_error is disabled" do
      let(:skip_on_error) { false }

      it "consumer crashes without committing offsets" do
        expect(kafka_client).not_to receive(:mark_as_consumed!)
        allow(Rails.logger).to receive(:error)
        expect {
          consume_with_sbmt_karafka
        }.to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
          .with_tags(
            inbox_name: "test_inbox_item",
            event_name: "test-event-name",
            status: "failure"
          )
      end
    end
  end

  context "when got exception from inbox item creator" do
    before do
      allow(Sbmt::Outbox::CreateInboxItem).to receive(:call)
        .and_raise("test exception")
    end

    it "let consumer crash without committing offsets" do
      expect(kafka_client).not_to receive(:mark_as_consumed!)
      allow(Rails.logger).to receive(:error)
      expect {
        consume_with_sbmt_karafka
      }.to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: "test-event-name",
          status: "failure"
        )
    end
  end

  context "with poisoned message" do
    before do
      allow(Rails.logger).to receive(:info).with(/Successfully consumed/)
      allow(Rails.logger).to receive(:error)
    end

    shared_examples "successful consumer" do
      it "successfully consumes" do
        expect(kafka_client).to receive(:mark_as_consumed!)
        expect { consume_with_sbmt_karafka }
          .to change(TestInboxItem, :count).by(1)
          .and increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
          .with_tags(
            inbox_name: "test_inbox_item",
            event_name: "test-event-name",
            status: "success"
          )
      end
    end

    shared_examples "empty key consumer" do
      it_behaves_like "successful consumer"
      it "uses a message offset value and logs error" do
        consume_with_sbmt_karafka
        expect(TestInboxItem.last.event_key).to eq(message_offset)
        expect(Rails.logger).to have_received(:error).with(
          "message has no partitioning key, headers: #{headers}"
        )
      end
    end

    context "when message idempotency header does not exist" do
      before do
        stub_const(
          "Sbmt::KafkaConsumer::InboxConsumer::IDEMPOTENCY_HEADER_NAME",
          "non-existent-header"
        )
      end

      it_behaves_like "successful consumer"

      it "successfully uses generated value" do
        consume_with_sbmt_karafka
        expect(UUID.validate(TestInboxItem.last.uuid)).to be(true)
        expect(Rails.logger).to have_received(:error).with(
          "message has no uuid, headers: #{headers}"
        )
      end

      context "when outbox_producer is false" do
        let(:outbox_producer) { false }

        it "uses message offset value" do
          consume_with_sbmt_karafka
          expect(Rails.logger).not_to have_received(:error)
        end
      end
    end

    context "when message key header is empty" do
      let(:message_key) { "" }

      it_behaves_like "empty key consumer"
    end

    context "when message key header is nil" do
      let(:message_key) { nil }

      it_behaves_like "empty key consumer"
    end
  end

  context "when there is the same inbox item exists" do
    before do
      create(:inbox_item, uuid: uuid)
    end

    it "skips creating a new one" do
      expect(kafka_client).to receive(:mark_as_consumed!)
      allow(Rails.logger).to receive(:error)
      expect { consume_with_sbmt_karafka }
        .to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: "test-event-name",
          status: "duplicate"
        )
        .and not_change(TestInboxItem, :count)
    end
  end

  context "when extra_message_attrs is used" do
    let(:consumer) do
      consumer_class = Class.new(klass) do
        def extra_message_attrs(_message)
          {event_name: "custom-value"}
        end
      end

      build_consumer(consumer_class.new)
    end

    it "merges with default inbox-item attributes" do
      expect(kafka_client).to receive(:mark_as_consumed!)
      expect(Rails.logger).to receive(:info).with(/Successfully consumed/).twice
      expect { consume_with_sbmt_karafka }.to change(TestInboxItem, :count).by(1)
      expect(TestInboxItem.last.event_name).to eq("custom-value")
    end
  end
end
