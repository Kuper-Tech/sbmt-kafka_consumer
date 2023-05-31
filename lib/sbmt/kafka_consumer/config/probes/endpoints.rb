# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Probes::Endpoints < Dry::Struct
  transform_keys(&:to_sym)

  attribute :liveness, Sbmt::KafkaConsumer::Config::Probes::LivenessProbe.optional.default(
    Sbmt::KafkaConsumer::Config::Probes::LivenessProbe.new.freeze
  )

  attribute :readiness, Sbmt::KafkaConsumer::Config::Probes::ReadinessProbe.optional.default(
    Sbmt::KafkaConsumer::Config::Probes::ReadinessProbe.new.freeze
  )
end
