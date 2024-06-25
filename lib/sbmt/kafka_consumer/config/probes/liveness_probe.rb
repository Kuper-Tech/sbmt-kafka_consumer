# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Probes::LivenessProbe < Dry::Struct
  transform_keys(&:to_sym)

  attribute :enabled, Sbmt::KafkaConsumer::Types::Bool.optional.default(true)
  attribute :path, Sbmt::KafkaConsumer::Types::Strict::String
    .optional
    .default("/liveness")
  attribute :timeout, Sbmt::KafkaConsumer::Types::Coercible::Integer.optional.default(10)
  attribute :max_error_count, Sbmt::KafkaConsumer::Types::Coercible::Integer.optional.default(10)
end
