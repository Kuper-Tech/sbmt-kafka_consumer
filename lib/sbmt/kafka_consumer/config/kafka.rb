# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Kafka < Anyway::Config
  SERVERS_REGEXP = /^[\w\d.\-:,]+$/.freeze

  config_name :kafka_consumer_kafka
  attr_config :servers, rdkafka: {}

  required :servers
  coerce_types servers: {type: :string, array: false}

  on_load :ensure_options_are_valid

  def to_rdkafka_options
    # servers takes precedence over rdkafka
    rdkafka
      .merge("bootstrap.servers": servers)
      .symbolize_keys
  end

  private

  def ensure_options_are_valid
    raise_validation_error "invalid servers: #{servers}, should be in format: \"host1:port1,host2:port2,...\"" unless SERVERS_REGEXP.match?(servers)
  end
end
