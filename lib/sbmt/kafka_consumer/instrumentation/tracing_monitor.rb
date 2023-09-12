# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class TracingMonitor < ChainableMonitor
        def initialize
          tracers = []
          tracers << OpenTelemetryTracer if defined?(OpenTelemetryTracer)
          tracers << SentryTracer if defined?(SentryTracer)

          super(tracers)
        end
      end
    end
  end
end
