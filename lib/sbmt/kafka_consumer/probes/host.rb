# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Probes
      class Host
        def self.run_async
          config = Sbmt::KafkaConsumer::Config.new
          app = health_check_app(config.probes[:endpoints])
          port = config.probes[:port]
          start_server_async(app, port)
        end

        def self.health_check_app(config)
          ::HttpHealthCheck::RackApp.configure do |c|
            c.logger Rails.logger unless Rails.env.production?

            liveness = config[:liveness]
            if liveness[:enabled]
              c.probe liveness[:path], Sbmt::KafkaConsumer::Instrumentation::LivenessListener.new(
                timeout_sec: liveness[:timeout]
              )
            end

            readiness = config[:readiness]
            if readiness[:enabled]
              c.probe readiness[:path], Sbmt::KafkaConsumer::Instrumentation::ReadinessListener.new
            end
          end
        end

        private_class_method :health_check_app

        def self.start_server_async(app, port)
          Thread.new do
            ::Rack::Handler::WEBrick.run(
              ::Rack::Builder.new do
                use ::Yabeda::Prometheus::Exporter if defined?(Yabeda)
                run app
              end,
              Host: "0.0.0.0",
              Port: port
            )
          end
        end

        private_class_method :start_server_async
      end
    end
  end
end
