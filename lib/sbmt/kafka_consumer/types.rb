# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Types
      include Dry.Types

      ConfigAttrs = Dry::Types["hash"].constructor { |hsh| hsh.deep_symbolize_keys }

      ConfigConsumer = Types.Constructor(Config::Consumer)
      ConfigDeserializer = Types.Constructor(Config::Deserializer)
      ConfigTopic = Types.Constructor(Config::Topic)
    end
  end
end
