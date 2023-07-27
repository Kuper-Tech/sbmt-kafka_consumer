# frozen_string_literal: true

require "rails/generators/named_base"
require "generators/kafka_consumer/concerns/configuration"

module KafkaConsumer
  module Generators
    class ConsumerGenerator < Rails::Generators::NamedBase
      include Concerns::Configuration

      source_root File.expand_path("templates", __dir__)

      def insert_consumer_class
        @consumer_name = "#{name.classify}Consumer"
        template "consumer.rb.erb", "app/consumers/#{file_path}_consumer.rb"
      end

      def configure_consumer_group
        @group_key = ask "Would you also configure a consumer group?" \
                    " Type the group's key (e.g. my_consumer_group) or press Enter to skip this action"
        return if @group_key.blank?

        check_config_file!

        @group_name = ask "Type the group's name (e.g. my.consumer.group)"
        @topic = ask "Type the group topic's name"
        insert_into_file CONFIG_PATH, group_template.result(binding), after: "consumer_groups:\n"
      end

      private

      def group_template_path
        File.join(ConsumerGenerator.source_root, "consumer_group.yml.erb")
      end

      def group_template
        ERB.new(File.read(group_template_path), trim_mode: "%-")
      end
    end
  end
end
