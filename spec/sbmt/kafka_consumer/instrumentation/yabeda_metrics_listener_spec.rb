# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::Instrumentation::YabedaMetricsListener do
  let(:event) { double("event") }

  let(:inbox_name) { "inbox" }
  let(:event_name) { "event" }
  let(:status) { "status" }

  describe ".on_consumer_consumed_one" do
    let(:message) { double("message") }
    let(:metadata) { OpenStruct.new(topic: "topic", partition: 0) }

    it "increments consumer metric" do
      expect(event).to receive(:[]).with(:message).and_return(message)
      expect(message).to receive(:metadata).and_return(metadata).twice

      expect { described_class.new.on_consumer_consumed_one(event) }
        .to increment_yabeda_counter(Yabeda.kafka_consumer.consumes)
        .with_tags(topic: "topic", partition: 0)
    end
  end

  describe ".on_consumer_inbox_consumed_one" do
    it "increments consumer metric" do
      expect(event).to receive(:[]).with(:inbox_name).and_return(inbox_name)
      expect(event).to receive(:[]).with(:event_name).and_return(event_name)
      expect(event).to receive(:[]).with(:status).and_return(status)

      expect { described_class.new.on_consumer_inbox_consumed_one(event) }
        .to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: inbox_name,
          event_name: event_name,
          status: status
        )
    end
  end

  describe ".on_error_occurred" do
    let(:message) { double("message") }
    let(:metadata) { OpenStruct.new(topic: "topic", partition: 0) }

    it "increments consumer metric for base consumer" do
      expect(event).to receive(:[]).with(:type).and_return("consumer.base.consume_one")
      expect(event).to receive(:[]).with(:message).and_return(message)
      expect(message).to receive(:metadata).and_return(metadata).twice

      expect { described_class.new.on_error_occurred(event) }
        .to increment_yabeda_counter(Yabeda.kafka_consumer.consumes)
        .with_tags(topic: "topic", partition: 0)
    end

    it "increments consumer metric for inbox consumer" do
      expect(event).to receive(:[]).with(:type).and_return("consumer.inbox.consume_one")
      expect(event).to receive(:[]).with(:inbox_name).and_return(inbox_name)
      expect(event).to receive(:[]).with(:event_name).and_return(event_name)
      expect(event).to receive(:[]).with(:status).and_return(status)

      expect { described_class.new.on_error_occurred(event) }
        .to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
        .with_tags(
          inbox_name: inbox_name,
          event_name: event_name,
          status: status
        )
    end

    it "doesn't increment consumer metric for other cases" do
      expect(event).to receive(:[]).with(:type).and_return("other.error")

      expect { described_class.new.on_error_occurred(event) }
        .not_to increment_yabeda_counter(Yabeda.kafka_consumer.inbox_consumes)
    end
  end
end
