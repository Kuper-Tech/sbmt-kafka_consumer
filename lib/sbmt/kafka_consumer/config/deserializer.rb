# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Deserializer < Dry::Struct
  transform_keys(&:to_sym)

  attribute? :klass, Sbmt::KafkaConsumer::Types::Strict::String.optional
  attribute? :init_attrs, Sbmt::KafkaConsumer::Types::ConfigAttrs.default({}.freeze)

  def instantiate
    return klass.constantize.new if init_attrs.blank?
    klass.constantize.new(**init_attrs)
  end
end
