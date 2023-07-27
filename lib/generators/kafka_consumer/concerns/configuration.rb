# frozen_string_literal: true

module KafkaConsumer
  module Generators
    module Concerns
      module Configuration
        extend ActiveSupport::Concern

        CONFIG_PATH = "config/kafka_consumer.yml"

        def check_config_file!
          config_path = File.expand_path(CONFIG_PATH)
          return if File.exist?(config_path)

          generate = ask "The file #{config_path} does not appear to exist. " \
                       "Would you like to generate it? [Yn]"

          generator_name = "kafka_consumer:install"
          if (generate.presence || "y").casecmp("y").zero?
            generate generator_name
          else
            raise Rails::Generators::Error, "Please generate #{config_path} " \
                           "by running `bin/rails g #{generator_name}` " \
                           "or add this file manually."
          end
        end
      end
    end
  end
end
