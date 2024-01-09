# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Metrics < Dry::Struct
  transform_keys(&:to_sym)

  attribute? :port, Sbmt::KafkaConsumer::Types::Coercible::Integer.optional
  attribute :path, Sbmt::KafkaConsumer::Types::Strict::String
    .optional
    .default("/metrics")
end
