# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Routing
      module ConsumerMapper
        class Base
          # @param raw_consumer_group_name [String, Symbol] string or symbolized consumer group name
          # @return [String] remapped final consumer group name
          def call(raw_consumer_group_name)
            raise "Implement #call in a subclass"
          end
        end
      end
    end
  end
end
