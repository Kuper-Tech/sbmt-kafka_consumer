# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Probes < Dry::Struct
  transform_keys(&:to_sym)

  attribute :port, Sbmt::KafkaConsumer::Types::Coercible::Integer.optional.default(9394)
  attribute :endpoints, Endpoints.optional.default(Endpoints.new.freeze)
end
