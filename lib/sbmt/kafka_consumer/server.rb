# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class Server < SbmtKarafka::Server
      class << self
        # original klass tries to validate karafka-specific server cli-options which we override
        # see SbmtKarafka::Server for details
        def run
          SbmtKarafka::Server.listeners = []
          SbmtKarafka::Server.workers = []

          process.on_sigint { SbmtKarafka::Server.stop }
          process.on_sigquit { SbmtKarafka::Server.stop }
          process.on_sigterm { SbmtKarafka::Server.stop }
          process.on_sigtstp { SbmtKarafka::Server.quiet }
          process.supervise

          $stdout.puts "Starting server"
          SbmtKarafka::Server.start

          sleep(0.1) until SbmtKarafka::App.terminated?
          # rubocop:disable Lint/RescueException
        rescue Exception => e
          $stdout.puts "Cannot start server: #{e.message}"

          # rubocop:enable Lint/RescueException
          SbmtKarafka::Server.stop

          raise e
        end
      end
    end
  end
end
