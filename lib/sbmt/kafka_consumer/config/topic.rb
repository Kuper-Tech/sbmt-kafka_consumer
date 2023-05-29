# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Topic < Dry::Struct
  transform_keys(&:to_sym)

  attribute :name, Sbmt::KafkaConsumer::Types::Strict::String
  attribute :consumer, Sbmt::KafkaConsumer::Types::ConfigConsumer
  attribute :deserializer, Sbmt::KafkaConsumer::Types::ConfigDeserializer
    .optional
    .default(Sbmt::KafkaConsumer::Config::Deserializer.new.freeze)
  attribute :active, Sbmt::KafkaConsumer::Types::Bool.optional.default(true)
  attribute :manual_offset_management, Sbmt::KafkaConsumer::Types::Bool.optional.default(true)
end
