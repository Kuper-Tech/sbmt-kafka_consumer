# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class ReadinessListener
        include ListenerHelper
        include KafkaConsumer::Probes::Probe

        def initialize
          setup_subscription
        end

        def on_app_running(_event)
          @ready = true
        end

        def on_app_stopping(_event)
          @ready = false
        end

        def probe(_env)
          ready? ? probe_ok(ready: true) : probe_error(ready: false)
        end

        private

        def ready?
          @ready
        end

        def setup_subscription
          SbmtKarafka::App.monitor.subscribe(self)
        end
      end
    end
  end
end
