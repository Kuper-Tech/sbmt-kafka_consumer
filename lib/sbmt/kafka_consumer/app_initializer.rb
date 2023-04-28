# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module AppInitializer
      # TODO: customize in config
      DEFAULT_LOGGER_CLASS = Sbmt::KafkaConsumer::Logger
      DEFAULT_MONITOR_CLASS = Instrumentation::SentryMonitor
      DEFAULT_LOGGER_LISTENER_CLASS = Instrumentation::LoggerListener
      DEFAULT_METRICS_LISTENER_CLASS = Instrumentation::YabedaMetricsListener

      extend self

      def initialize!
        # TODO: configure karafka via config file
        SbmtKarafka::App.setup do |config|
          config.monitor = DEFAULT_MONITOR_CLASS.new
          config.logger = DEFAULT_LOGGER_CLASS.new
        end

        SbmtKarafka.monitor.subscribe(DEFAULT_LOGGER_LISTENER_CLASS.new)
        SbmtKarafka.monitor.subscribe(DEFAULT_METRICS_LISTENER_CLASS.new)
      end
    end
  end
end
