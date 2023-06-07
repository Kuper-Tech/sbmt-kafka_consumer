module Sbmt
  module KafkaConsumer
    module Routing
      class KarafkaV1ConsumerMapper < SbmtKarafka::Routing::ConsumerMapper
        def call(raw_consumer_group_name)
          client_id = ActiveSupport::Inflector.underscore(SbmtKarafka::App.config.client_id).tr("/", "_")
          "#{client_id}_#{raw_consumer_group_name}"
        end
      end
    end
  end
end
