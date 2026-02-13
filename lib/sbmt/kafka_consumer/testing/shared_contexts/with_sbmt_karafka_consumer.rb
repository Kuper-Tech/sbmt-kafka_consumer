# frozen_string_literal: true

RSpec.shared_context "with sbmt karafka consumer" do
  subject(:consume_with_sbmt_karafka) do
    coordinator.increment(:consume)
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
  let(:client_configurer_options) { {skip_regexp_consumers_init: true} }

  let(:consumer_class) { described_class.consumer_klass }
  let(:consumer) { build_consumer(consumer_class.new) }

  before {
    Sbmt::KafkaConsumer::ClientConfigurer.configure!(**client_configurer_options)
    allow(kafka_client).to receive(:assignment_lost?).and_return(false)
    allow(kafka_client).to receive(:mark_as_consumed!).and_return(true)
    allow(kafka_client).to receive(:mark_as_consumed).and_return(true)
  }

  def publish_to_sbmt_karafka(raw_payload, opts = {})
    message = Karafka::Messages::Message.new(raw_payload, Karafka::Messages::Metadata.new(build_metadata_hash(opts)))
    consumer.messages = consumer_messages([message])
  end

  def publish_to_sbmt_karafka_batch(raw_payloads, opts = {})
    messages = raw_payloads.map do |p|
      Karafka::Messages::Message.new(p, Karafka::Messages::Metadata.new(build_metadata_hash(opts)))
    end
    consumer.messages = consumer_messages(messages)
  end

  # @return [Hash] message default options
  def build_metadata_hash(opts)
    {
      deserializers: test_topic.deserializers(payload: opts[:deserializer] || null_deserializer),
      raw_headers: opts[:headers] || {},
      raw_key: opts[:key],
      offset: opts[:offset] || 0,
      partition: opts[:partition] || 0,
      received_at: opts[:received_at] || Time.current,
      topic: opts[:topic] || test_topic.name
    }
  end

  def build_consumer(instance)
    instance.coordinator = coordinator
    instance.client = kafka_client
    instance.singleton_class.include Karafka::Processing::Strategies::Default
    instance
  end

  private

  def consumer_messages(messages)
    Karafka::Messages::Messages.new(
      messages,
      Karafka::Messages::BatchMetadata.new(
        topic: test_topic.name,
        partition: 0,
        processed_at: Time.zone.now,
        created_at: Time.zone.now
      )
    )
  end
end
