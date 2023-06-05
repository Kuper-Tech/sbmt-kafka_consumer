# frozen_string_literal: true

RSpec.shared_context "with sbmt karafka consumer" do
  subject(:consume_with_sbmt_karafka) do
    coordinator.increment
    consumer.on_consume
  end

  let(:coordinator) {
    instance = SbmtKarafka::Processing::Coordinator.new(test_topic, 0, instance_double(SbmtKarafka::TimeTrackers::Pause))
    instance.instance_variable_set(:@seek_offset, -1)
    instance
  }
  let(:test_consumer_group) { SbmtKarafka::Routing::ConsumerGroup.new(:test_group) }
  let(:test_topic) { SbmtKarafka::Routing::Topic.new(:test_topic, test_consumer_group) }
  let(:test_subscription_group) { SbmtKarafka::Routing::SubscriptionGroup.new(0, [test_topic]) }
  let(:kafka_client) { SbmtKarafka::Connection::Client.new(test_subscription_group) }
  let(:null_deserializer) { Sbmt::KafkaConsumer::Serialization::NullDeserializer.new }

  let(:consumer) {
    build_consumer(described_class.new)
  }

  before {
    Sbmt::KafkaConsumer::ClientConfigurer.configure!
    allow(kafka_client).to receive(:mark_as_consumed!).and_return(true)
  }

  def publish_to_sbmt_karafka(raw_payload, opts = {})
    message = SbmtKarafka::Messages::Message.new(raw_payload, SbmtKarafka::Messages::Metadata.new(metadata_defaults.merge(opts)))
    consumer.messages = SbmtKarafka::Messages::Messages.new(
      [message],
      SbmtKarafka::Messages::BatchMetadata.new(
        topic: test_topic.name,
        partition: 0,
        processed_at: Time.zone.now,
        created_at: Time.zone.now
      )
    )
  end

  # @return [Hash] message default options
  def metadata_defaults
    {
      deserializer: null_deserializer,
      headers: {},
      key: nil,
      offset: 0,
      partition: 0,
      received_at: Time.current,
      topic: test_topic.name
    }
  end

  def build_consumer(instance)
    instance.coordinator = coordinator
    instance.client = kafka_client
    instance.singleton_class.include SbmtKarafka::Processing::Strategies::Default
    instance
  end
end
