# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Kafka < Dry::Struct
  transform_keys(&:to_sym)

  # srv1:port1,srv2:port2,...
  SERVERS_REGEXP = /^[a-z\d.\-:]+(,[a-z\d.\-:]+)*$/.freeze

  attribute :servers, Sbmt::KafkaConsumer::Types::String.constrained(format: SERVERS_REGEXP)
  attribute? :kafka_options, Sbmt::KafkaConsumer::Types::ConfigAttrs.default({}.freeze)

  def to_kafka_options
    # servers takes precedence over kafka_options
    kafka_options
      .merge("bootstrap.servers": servers)
      .symbolize_keys
  end
end
