# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::ConsumerGroup < Dry::Struct
  transform_keys(&:to_sym)

  attribute :name, Sbmt::KafkaConsumer::Types::Strict::String
  attribute :topics, Sbmt::KafkaConsumer::Types.Array(Sbmt::KafkaConsumer::Types::ConfigTopic)
end
