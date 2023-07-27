# frozen_string_literal: true

require "rails/generators/base"
require "generators/kafka_consumer/concerns/configuration"

module KafkaConsumer
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Concerns::Configuration

      source_root File.expand_path("templates", __dir__)

      def create_kafkafile
        copy_file "Kafkafile", "./Kafkafile"
      end

      def create_kafka_consumer_yml
        copy_file "kafka_consumer.yml", CONFIG_PATH
      end
    end
  end
end
