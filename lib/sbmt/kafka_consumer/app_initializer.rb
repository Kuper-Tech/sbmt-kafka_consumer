# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module AppInitializer
      extend self

      def initialize!
        ClientConfigurer.configure!
      end
    end
  end
end
