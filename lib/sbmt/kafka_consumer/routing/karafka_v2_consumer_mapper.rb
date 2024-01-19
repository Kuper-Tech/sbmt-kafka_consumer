module Sbmt
  module KafkaConsumer
    module Routing
      # uses default karafka v2 mapper
      # exists just for naming consistency with KarafkaV1ConsumerMapper
      class KarafkaV2ConsumerMapper < Karafka::Routing::ConsumerMapper; end
    end
  end
end
