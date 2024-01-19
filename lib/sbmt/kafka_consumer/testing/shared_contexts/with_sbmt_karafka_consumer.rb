# frozen_string_literal: true

RSpec.shared_context "with sbmt karafka consumer" do
  subject(:consume_with_sbmt_karafka) do
    coordinator.increment
    consumer.on_consume
  end

  let(:coordinator) {
    instance = Karafka::Processing::Coordinator.new(test_topic, 0, instance_double(Karafka::TimeTrackers::Pause))
    instance.instance_variable_set(:@seek_offset, -1)
    instance
  }
  let(:test_consumer_group) { Karafka::Routing::ConsumerGroup.new(:test_group) }
  let(:test_topic) { Karafka::Routing::Topic.new(:test_topic, test_consumer_group) }
  let(:kafka_client) { instance_double(Karafka::Connection::Client) }
  let(:null_deserializer) { Sbmt::KafkaConsumer::Serialization::NullDeserializer.new }

  let(:consumer) {
    build_consumer(described_class.new)
  }

  before {
    Sbmt::KafkaConsumer::ClientConfigurer.configure!
    allow(kafka_client).to receive(:assignment_lost?).and_return(false)
    allow(kafka_client).to receive(:mark_as_consumed!).and_return(true)
  }

  def publish_to_sbmt_karafka(raw_payload, opts = {})
    message = Karafka::Messages::Message.new(raw_payload, Karafka::Messages::Metadata.new(metadata_defaults.merge(opts)))
    consumer.messages = Karafka::Messages::Messages.new(
      [message],
      Karafka::Messages::BatchMetadata.new(
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
    instance.singleton_class.include Karafka::Processing::Strategies::Default
    instance
  end
end
