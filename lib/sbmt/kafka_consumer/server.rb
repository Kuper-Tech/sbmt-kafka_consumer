# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class Server < Karafka::Server
      class << self
        # original klass tries to validate karafka-specific server cli-options which we override
        # see Karafka::Server for details
        def run
          Karafka::Server.listeners = []
          Karafka::Server.workers = []

          process.on_sigint { Karafka::Server.stop }
          process.on_sigquit { Karafka::Server.stop }
          process.on_sigterm { Karafka::Server.stop }
          process.on_sigtstp { Karafka::Server.quiet }
          process.supervise

          $stdout.puts "Starting server"
          Karafka::Server.start

          sleep(0.1) until Karafka::App.terminated?
          # rubocop:disable Lint/RescueException
        rescue Exception => e
          $stdout.puts "Cannot start server: #{e.message}"

          # rubocop:enable Lint/RescueException
          Karafka::Server.stop

          raise e
        end
      end
    end
  end
end
