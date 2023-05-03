# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config < Anyway::Config
  config_name :kafka_consumer

  attr_config :client_id,
    :pause_timeout, :pause_max_timeout, :pause_with_exponential_backoff,
    :max_wait_time, :shutdown_timeout, :concurrency,
    auth: {}, kafka: {},
    deserializer_class: "::Sbmt::KafkaConsumer::Serialization::JsonDeserializer",
    monitor_class: "::Sbmt::KafkaConsumer::Instrumentation::SentryMonitor",
    logger_class: "::Sbmt::KafkaConsumer::Logger",
    logger_listener_class: "::Sbmt::KafkaConsumer::Instrumentation::LoggerListener",
    metrics_listener_class: "::Sbmt::KafkaConsumer::Instrumentation::YabedaMetricsListener"

  required :client_id

  coerce_types client_id: :string,
    pause_timeout: :integer,
    pause_max_timeout: :integer,
    pause_with_exponential_backoff: :boolean,
    max_wait_time: :integer,
    shutdown_timeout: :integer,
    concurrency: :integer
  coerce_types kafka: {config: Kafka}
  coerce_types auth: {config: Auth}

  def to_rdkafka_options
    kafka.to_rdkafka_options
      .merge(auth.to_rdkafka_options)
  end
end
