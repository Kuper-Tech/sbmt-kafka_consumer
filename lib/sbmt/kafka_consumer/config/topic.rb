# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Topic < Dry::Struct
  transform_keys(&:to_sym)

  attribute :name, Sbmt::KafkaConsumer::Types::Strict::String
  attribute :consumer, Sbmt::KafkaConsumer::Types::ConfigConsumer
  attribute :deserializer, Sbmt::KafkaConsumer::Types::ConfigDeserializer.optional
  attribute? :active, Sbmt::KafkaConsumer::Types::Bool.default(true)
end
