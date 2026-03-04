# frozen_string_literal: true

require "generators/kafka_consumer/regexp_consumer/regexp_consumer_generator"

RSpec.describe KafkaConsumer::Generators::RegexpConsumerGenerator do
  include Rails::Generators::Testing::Behavior
  include Rails::Generators::Testing::Assertions
  include FileUtils

  tests described_class

  around do |example|
    Dir.mktmpdir("kafka_consumer_regexp_consumer_generator_") do |tmpdir|
      @tmp_dir = tmpdir
      example.run
    end
  end

  def destination_root
    @tmp_dir
  end

  let(:kafka_consumer_yml) do
    <<~YAML
      default: &default
        client_id: "test-app"
        kafka:
          servers: "kafka:9092"
        consumer_groups:
      development:
        <<: *default
    YAML
  end

  before do
    mkdir_p File.join(destination_root, "config")
    File.write(File.join(destination_root, "config/kafka_consumer.yml"), kafka_consumer_yml)
  end

  def kc_content
    File.read(File.join(destination_root, "config/kafka_consumer.yml"))
  end

  describe "inbox consumer group (init_attrs, no deserializer)" do
    before do
      run_generator([
        "order",
        "Ecom::EventStreaming::Kafka::RegularEventsInboxConsumer",
        'seeker\.paas-stand\.event-streaming\.order(\.\d+)?$',
        "--env-prefix", "ES_ORDER",
        "--init-attrs", "inbox_item:EsOrderInboxItem"
      ])
    end

    it "adds consumer group key" do
      expect(kc_content).to include("'order':")
    end

    it "uses env_prefix for CONSUMER_GROUP_NAME env var" do
      expect(kc_content).to include("ES_ORDER_CONSUMER_GROUP_NAME")
    end

    it "uses group_key as default group name" do
      expect(kc_content).to include('"order"')
    end

    it "includes CONSUMER_GROUP_SUFFIX env fetch" do
      expect(kc_content).to include('ENV.fetch("CONSUMER_GROUP_SUFFIX", "")')
    end

    it "uses env_prefix for TOPIC_REGEXP env var" do
      expect(kc_content).to include("ES_ORDER_TOPIC_REGEXP")
    end

    it "embeds topic_regexp as default" do
      expect(kc_content).to include('seeker\.paas-stand\.event-streaming\.order(\.\d+)?$')
    end

    it "sets consumer klass" do
      expect(kc_content).to include('klass: "Ecom::EventStreaming::Kafka::RegularEventsInboxConsumer"')
    end

    it "emits init_attrs with quoted string value" do
      expect(kc_content).to include('inbox_item: "EsOrderInboxItem"')
    end

    it "does not emit a deserializer section" do
      expect(kc_content).not_to include("deserializer:")
    end
  end

  describe "consumer group with deserializer and no init_attrs" do
    before do
      run_generator([
        "init_exports",
        "Ecom::EventStreaming::Kafka::ControlRequestsConsumer",
        'yc\.seeker\.paas-stand\.event-streaming\.control\.in(\.\d+)?',
        "--env-prefix", "ES_CONTROL_REQUESTS",
        "--deserializer-klass", "Sbmt::KafkaConsumer::Serialization::JsonDeserializer"
      ])
    end

    it "adds consumer group key" do
      expect(kc_content).to include("'init_exports':")
    end

    it "uses env_prefix for CONSUMER_GROUP_NAME env var" do
      expect(kc_content).to include("ES_CONTROL_REQUESTS_CONSUMER_GROUP_NAME")
    end

    it "uses env_prefix for TOPIC_REGEXP env var" do
      expect(kc_content).to include("ES_CONTROL_REQUESTS_TOPIC_REGEXP")
    end

    it "sets consumer klass" do
      expect(kc_content).to include('klass: "Ecom::EventStreaming::Kafka::ControlRequestsConsumer"')
    end

    it "emits deserializer section" do
      expect(kc_content).to include('klass: "Sbmt::KafkaConsumer::Serialization::JsonDeserializer"')
    end

    it "does not emit init_attrs section" do
      expect(kc_content).not_to include("init_attrs:")
    end
  end

  describe "consumer group with init_attrs (including boolean) and deserializer" do
    before do
      run_generator([
        "seeker_init_exports",
        "SeekerInitEventsConsumer",
        'seeker\.paas-stand\.event-streaming\.order\.init(\.\d+)?$',
        "--env-prefix", "ES_SEEKER_INIT_EXPORTS",
        "--init-attrs",
        "envelope_schema:cloud-events.init.envelope",
        "data_schema:seeker.paas-stand.event-streaming.order.init",
        "skip_on_error:true",
        "--deserializer-klass", "Sbmt::KafkaConsumer::Serialization::JsonDeserializer"
      ])
    end

    it "adds consumer group key" do
      expect(kc_content).to include("'seeker_init_exports':")
    end

    it "emits string init_attrs with quotes" do
      expect(kc_content).to include('envelope_schema: "cloud-events.init.envelope"')
      expect(kc_content).to include('data_schema: "seeker.paas-stand.event-streaming.order.init"')
    end

    it "emits boolean init_attr without quotes" do
      expect(kc_content).to include("skip_on_error: true")
      expect(kc_content).not_to include('skip_on_error: "true"')
    end

    it "emits deserializer section" do
      expect(kc_content).to include('klass: "Sbmt::KafkaConsumer::Serialization::JsonDeserializer"')
    end
  end

  describe "missing kafka_consumer.yml" do
    before { FileUtils.rm_f(File.join(destination_root, "config/kafka_consumer.yml")) }

    let(:base_args) do
      [
        "order",
        "Ecom::EventStreaming::Kafka::RegularEventsInboxConsumer",
        'seeker\.paas-stand\.event-streaming\.order(\.\d+)?$'
      ]
    end

    let(:base_opts) { {env_prefix: "ES_ORDER"} }

    it "delegates to kafka_consumer:install when user agrees" do
      calls = []
      gen = generator(base_args, base_opts)
      gen.define_singleton_method(:ask) { |*| "y" }
      gen.define_singleton_method(:generate) do |*args|
        calls << args
        next unless args.first == "kafka_consumer:install"
        File.write(
          File.join(destination_root, "config/kafka_consumer.yml"),
          "default: &default\n  consumer_groups:\n"
        )
      end
      gen.invoke_all
      expect(calls).to include(["kafka_consumer:install"])
    end

    it "raises Rails::Generators::Error when user declines" do
      gen = generator(base_args, base_opts)
      gen.define_singleton_method(:ask) { |*| "n" }
      expect { gen.invoke_all }.to raise_error(Rails::Generators::Error, /kafka_consumer:install/)
    end
  end
end
