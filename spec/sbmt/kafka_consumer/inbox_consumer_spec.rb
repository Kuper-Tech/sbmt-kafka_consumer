# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::InboxConsumer do
  include_context "with sbmt karafka consumer"

  let(:klass) do
    described_class.consumer_klass(
      name: "test_items",
      event_name: "test-event-name",
      inbox_item: "TestInboxItem",
      skip_on_error: skip_on_error
    )
  end

  let(:skip_on_error) { false }
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

      it "consumer skips failed message and continues processing" do
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
        let(:observable_inbox_consumer) do
          Class.new(klass) do
            attr_reader :attempts

            private

            def retry_backoff
              @attempts ||= 1

              proc do
                @attempts += 1
                0
              end
            end
          end
        end
        let(:consumer) { build_consumer(observable_inbox_consumer.new) }

        before do
          allow(Sbmt::Outbox::CreateInboxItem)
            .to receive(:call).and_raise(ActiveRecord::StatementInvalid)
        end

        it "retries consuming process" do
          allow(Rails.logger).to receive(:error)

          expect(Sbmt::KafkaConsumer::ActiveRecordHelper).to receive(:clear_active_connections!).exactly(4)

          expect { consume_with_sbmt_karafka }
            .not_to raise_error

          expect(consumer.attempts).to eq(5)
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

  context "when message idempotency header does not exist" do
    before do
      stub_const("Sbmt::KafkaConsumer::InboxConsumer::IDEMPOTENCY_HEADER_NAME", "non-existent-header")
    end

    it "successfully uses generated value" do
      expect(kafka_client).to receive(:mark_as_consumed!)
      allow(Rails.logger).to receive(:info).with(/Successfully consumed/)
      expect { consume_with_sbmt_karafka }
        .to change(TestInboxItem, :count).by(1)
        .and increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: "test-event-name",
          status: "success"
        )
      expect(UUID.validate(TestInboxItem.last.uuid)).to be(true)
    end
  end

  context "when message key header is empty" do
    let(:message_key) { "" }

    it "uses message offset value" do
      expect(kafka_client).to receive(:mark_as_consumed!)
      allow(Rails.logger).to receive(:info).with(/Successfully consumed/)
      expect { consume_with_sbmt_karafka }
        .to change(TestInboxItem, :count).by(1)
        .and increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: "test-event-name",
          status: "success"
        )
      expect(TestInboxItem.last.event_key).to eq(message_offset)
    end
  end

  context "when message key header is nil" do
    let(:message_key) { nil }

    it "uses message offset value" do
      expect(kafka_client).to receive(:mark_as_consumed!)
      allow(Rails.logger).to receive(:info).with(/Successfully consumed/)
      expect { consume_with_sbmt_karafka }
        .to change(TestInboxItem, :count).by(1)
        .and increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: "test_inbox_item",
          event_name: "test-event-name",
          status: "success"
        )
      expect(TestInboxItem.last.event_key).to eq(message_offset)
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
