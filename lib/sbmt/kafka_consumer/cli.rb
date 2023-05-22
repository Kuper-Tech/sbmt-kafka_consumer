# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    class CLI < Thor
      def self.exit_on_failure?
        true
      end

      default_command :start

      desc "start", "Start kafka_consumer worker"
      option :consumer_group_id,
        aliases: "-g",
        desc: "Consumer group id to start",
        repeatable: true
      option :concurrency,
        aliases: "-c",
        type: :numeric,
        default: 5,
        desc: "Number of threads, overrides global kafka.concurrency config"
      def start
        $stdout.puts "Initializing KafkaConsumer"
        $stdout.puts "Version: #{VERSION}"

        load_environment

        ClientConfigurer.configure!(
          consumer_groups: options[:consumer_group_id],
          concurrency: options[:concurrency]
        )
        Sbmt::KafkaConsumer::Server.run
      end

      private

      def load_environment
        env_file_path = ENV["KAFKAFILE"] || "#{Dir.pwd}/Kafkafile"

        if File.exist?(env_file_path)
          $stdout.puts "Loading env from Kafkafile: #{env_file_path}"
          load(env_file_path)
        end
      end
    end
  end
end
