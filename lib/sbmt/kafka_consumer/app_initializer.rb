# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module AppInitializer
      extend self

      def initialize!
        config = Config.new
        SbmtKarafka::App.setup do |karafka_config|
          karafka_config.monitor = config.monitor_class.classify.constantize.new
          karafka_config.logger = config.logger_class.classify.constantize.new
          karafka_config.deserializer = config.deserializer_class.classify.constantize.new

          karafka_config.client_id = config.client_id
          karafka_config.kafka = config.to_rdkafka_options

          karafka_config.pause_timeout = config.pause_timeout if config.pause_timeout.present?
          karafka_config.pause_max_timeout = config.pause_max_timeout if config.pause_max_timeout.present?
          karafka_config.pause_with_exponential_backoff = config.pause_with_exponential_backoff if config.pause_with_exponential_backoff.present?
          karafka_config.max_wait_time = config.max_wait_time if config.max_wait_time.present?
          karafka_config.shutdown_timeout = config.shutdown_timeout if config.shutdown_timeout.present?
          karafka_config.concurrency = config.concurrency if config.concurrency.present?

          # Recreate consumers with each batch. This will allow Rails code reload to work in the
          # development mode. Otherwise SbmtKarafka process would not be aware of code changes
          karafka_config.consumer_persistence = !Rails.env.development?
        end

        SbmtKarafka.monitor.subscribe(config.logger_listener_class.classify.constantize.new)
        SbmtKarafka.monitor.subscribe(config.metrics_listener_class.classify.constantize.new)
      end
    end
  end
end
