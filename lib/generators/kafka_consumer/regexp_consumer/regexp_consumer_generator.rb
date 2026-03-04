# frozen_string_literal: true

require "rails/generators/named_base"
require "generators/kafka_consumer/concerns/configuration"

module KafkaConsumer
  module Generators
    class RegexpConsumerGenerator < Rails::Generators::NamedBase
      include Concerns::Configuration

      source_root File.expand_path("templates", __dir__)

      desc "Injects a regexp-based consumer group entry into config/kafka_consumer.yml"

      argument :consumer_klass, type: :string,
        desc: "Consumer class name (e.g. Ecom::EventStreaming::Kafka::RegularEventsInboxConsumer)"

      argument :topic_regexp, type: :string,
        desc: "Topic regexp value (e.g. 'seeker\\.paas-stand\\.event-streaming\\.order(\\.\\d+)?\\$')"

      class_option :env_prefix, type: :string, required: true,
        desc: "ENV variable prefix for CONSUMER_GROUP_NAME and TOPIC_REGEXP (e.g. ES_ORDER)"

      class_option :init_attrs, type: :hash, default: {},
        banner: "key:value key:value",
        desc: "Consumer init_attrs as key:value pairs (e.g. inbox_item:Foo skip_on_error:true)"

      class_option :deserializer_klass, type: :string, default: nil,
        desc: "Deserializer class (omit to skip deserializer section)"

      def inject_consumer_group
        check_config_file!
        insert_into_file CONFIG_PATH, consumer_group_entry, after: "consumer_groups:\n"
      end

      private

      # Override to resolve path relative to destination_root (works in both
      # app context and generator tests with a tmpdir destination_root).
      def check_config_file!
        return if File.exist?(File.join(destination_root, CONFIG_PATH))

        generator_name = "kafka_consumer:install"
        answer = ask("The file #{CONFIG_PATH} does not appear to exist. Would you like to generate it? [Yn]")
        if (answer.presence || "y").casecmp("y").zero?
          generate generator_name
        else
          raise Rails::Generators::Error,
            "Please generate #{CONFIG_PATH} by running `bin/rails g #{generator_name}` or add this file manually."
        end
      end

      def group_key
        file_name
      end

      def env_prefix
        options[:env_prefix]
      end

      def init_attrs
        options[:init_attrs]
      end

      def deserializer_klass
        options[:deserializer_klass]
      end

      def format_attr_value(value)
        (value == "true" || value == "false") ? value : "\"#{value}\""
      end

      def consumer_group_entry
        template_path = File.join(self.class.source_root, "consumer_group.yml.erb")
        ERB.new(File.read(template_path), trim_mode: "%-").result(binding)
      end
    end
  end
end
