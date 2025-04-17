# frozen_string_literal: true

require "rack"
require "rackup/handler/webrick" if Gem::Version.new(::Rack.release) >= Gem::Version.new("3")

module Sbmt
  module KafkaConsumer
    module Probes
      class Host
        class << self
          def run_async
            config = Sbmt::KafkaConsumer::Config.new
            if config.probes[:port] == config.metrics[:port]
              start_on_single_port(config)
            else
              start_on_different_ports(config)
            end
          end

          def webrick
            return ::Rack::Handler::WEBrick if Gem::Version.new(::Rack.release) < Gem::Version.new("3")

            ::Rackup::Handler::WEBrick
          end

          private

          def health_check_app(config)
            ::HttpHealthCheck::RackApp.configure do |c|
              c.logger Rails.logger unless Rails.env.production?

              liveness = config[:liveness]
              if liveness[:enabled]
                c.probe liveness[:path], Sbmt::KafkaConsumer::Instrumentation::LivenessListener.new(
                  timeout_sec: liveness[:timeout], max_error_count: liveness[:max_error_count]
                )
              end

              readiness = config[:readiness]
              if readiness[:enabled]
                c.probe readiness[:path], Sbmt::KafkaConsumer::Instrumentation::ReadinessListener.new
              end
            end
          end

          def start_on_single_port(config)
            app = health_check_app(config.probes[:endpoints])
            middlewares = defined?(Yabeda) ? {::Yabeda::Prometheus::Exporter => {path: config.metrics[:path]}} : {}
            start_webrick(app, middlewares: middlewares, port: config.probes[:port])
          end

          def start_on_different_ports(config)
            ::HttpHealthCheck.run_server_async(
              port: config.probes[:port],
              rack_app: health_check_app(config.probes[:endpoints])
            )
            if defined?(Yabeda)
              start_webrick(
                Yabeda::Prometheus::Mmap::Exporter::NOT_FOUND_HANDLER,
                middlewares: {::Yabeda::Prometheus::Exporter => {path: config.metrics[:path]}},
                port: config.metrics[:port]
              )
            end
          end

          def start_webrick(app, middlewares:, port:)
            Thread.new do
              webrick.run(
                ::Rack::Builder.new do
                  middlewares.each do |middleware, options|
                    use middleware, **options
                  end
                  run app
                end,
                Host: "0.0.0.0",
                Port: port
              )
            end
          end
        end
      end
    end
  end
end
