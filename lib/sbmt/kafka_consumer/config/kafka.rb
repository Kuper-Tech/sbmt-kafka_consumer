# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Kafka < Dry::Struct
  transform_keys(&:to_sym)

  # srv1:port1,srv2:port2,...
  SERVERS_REGEXP = /^[a-z\d.\-:]+(,[a-z\d.\-:]+)*$/.freeze

  attribute :servers, Sbmt::KafkaConsumer::Types::String.constrained(format: SERVERS_REGEXP)

  # defaults are rdkafka's
  # see https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md
  attribute :heartbeat_timeout, Sbmt::KafkaConsumer::Types::Coercible::Integer.optional.default(5)
  attribute :session_timeout, Sbmt::KafkaConsumer::Types::Coercible::Integer.optional.default(30)
  attribute :reconnect_timeout, Sbmt::KafkaConsumer::Types::Coercible::Integer.optional.default(3)
  attribute :connect_timeout, Sbmt::KafkaConsumer::Types::Coercible::Integer.optional.default(5)
  attribute :socket_timeout, Sbmt::KafkaConsumer::Types::Coercible::Integer.optional.default(30)

  attribute :kafka_options, Sbmt::KafkaConsumer::Types::ConfigAttrs.optional.default({}.freeze)

  def to_kafka_options
    # root options take precedence over kafka_options' ones
    kafka_options.merge(
      "bootstrap.servers": servers,
      "heartbeat.interval.ms": heartbeat_timeout * 1_000,
      "session.timeout.ms": session_timeout * 1_000,
      "reconnect.backoff.max.ms": reconnect_timeout * 1_000,
      "socket.connection.setup.timeout.ms": connect_timeout * 1_000,
      "socket.timeout.ms": socket_timeout * 1_000
    ).symbolize_keys
  end
end
