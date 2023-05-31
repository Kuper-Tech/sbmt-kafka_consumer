# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Probes::ReadinessProbe < Dry::Struct
  transform_keys(&:to_sym)

  attribute :enabled, Sbmt::KafkaConsumer::Types::Bool.optional.default(true)
  attribute :path, Sbmt::KafkaConsumer::Types::Strict::String
    .optional
    .default("/readiness/kafka_consumer")
end
