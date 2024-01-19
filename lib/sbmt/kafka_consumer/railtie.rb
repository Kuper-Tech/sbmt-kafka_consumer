# frozen_string_literal: true

require "rails/railtie"

module Sbmt
  module KafkaConsumer
    class Railtie < Rails::Railtie
      initializer "sbmt_kafka_consumer_yabeda.configure_rails_initialization" do
        YabedaConfigurer.configure
      end

      # it must be consistent with sbmt_karafka initializers' name
      initializer "sbmt_kafka_consumer_karafka_init.configure_rails_initialization",
        before: "karafka.require_karafka_boot_file" do
        # skip loading native karafka.rb, because we want custom init process
        Karafka.instance_eval do
          def boot_file; false; end
        end
      end

      initializer "sbmt_kafka_consumer_opentelemetry_init.configure_rails_initialization",
        after: "opentelemetry.configure" do
        require "sbmt/kafka_consumer/instrumentation/open_telemetry_loader" if defined?(::OpenTelemetry)
      end

      config.after_initialize do
        require "sbmt/kafka_consumer/instrumentation/sentry_tracer" if defined?(::Sentry)
      end
    end
  end
end
