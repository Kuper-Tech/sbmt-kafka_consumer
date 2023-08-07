# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config < Anyway::Config
  config_name :kafka_consumer

  class << self
    def coerce_to(struct)
      lambda do |raw_attrs|
        struct.new(**raw_attrs)
      rescue Dry::Types::SchemaError => e
        raise_validation_error "cannot parse #{struct}: #{e.message}"
      end
    end

    def coerce_to_array_of(struct)
      lambda do |raw_attrs|
        raw_attrs.keys.map do |obj_title|
          coerce_to(struct)
            .call(**raw_attrs.fetch(obj_title)
                            .merge(id: obj_title))
        end
      end
    end
  end

  attr_config :client_id,
    :pause_timeout, :pause_max_timeout, :pause_with_exponential_backoff,
    :max_wait_time, :shutdown_timeout,
    concurrency: 4, auth: {}, kafka: {}, consumer_groups: {}, probes: {},
    deserializer_class: "::Sbmt::KafkaConsumer::Serialization::NullDeserializer",
    monitor_class: "::Sbmt::KafkaConsumer::Instrumentation::SentryMonitor",
    logger_class: "::Sbmt::KafkaConsumer::Logger",
    logger_listener_class: "::Sbmt::KafkaConsumer::Instrumentation::LoggerListener",
    metrics_listener_class: "::Sbmt::KafkaConsumer::Instrumentation::YabedaMetricsListener",
    consumer_mapper_class: "::Sbmt::KafkaConsumer::Routing::KarafkaV1ConsumerMapper"

  required :client_id

  on_load :validate_consumer_groups

  coerce_types client_id: :string,
    pause_timeout: :integer,
    pause_max_timeout: :integer,
    pause_with_exponential_backoff: :boolean,
    max_wait_time: :integer,
    shutdown_timeout: :integer,
    concurrency: :integer

  coerce_types kafka: coerce_to(Kafka)
  coerce_types auth: coerce_to(Auth)
  coerce_types probes: coerce_to(Probes)
  coerce_types consumer_groups: coerce_to_array_of(ConsumerGroup)

  def to_kafka_options
    kafka.to_kafka_options
      .merge(auth.to_kafka_options)
  end

  private

  def validate_consumer_groups
    consumer_groups.each do |cg|
      raise_validation_error "consumer group #{cg.id} must have at least one topic defined" if cg.topics.blank?
      cg.topics.each do |t|
        raise_validation_error "topic #{cg.id}.topics.name[#{t.name}] contains invalid consumer class: no const #{t.consumer.klass} defined" unless t.consumer.klass.safe_constantize
        raise_validation_error "topic #{cg.id}.topics.name[#{t.name}] contains invalid deserializer class: no const #{t.deserializer.klass} defined" unless t.deserializer&.klass&.safe_constantize
      end
    end
  end
end
