# frozen_string_literal: true

class Sbmt::KafkaConsumer::Config::Consumer < Dry::Struct
  transform_keys(&:to_sym)

  attribute :klass, Sbmt::KafkaConsumer::Types::Strict::String
  attribute? :init_attrs, Sbmt::KafkaConsumer::Types::ConfigAttrs.default({}.freeze)

  def instantiate
    target_klass = klass.constantize

    return target_klass.consumer_klass if init_attrs.blank?

    target_klass.consumer_klass(**init_attrs)
  end
end
