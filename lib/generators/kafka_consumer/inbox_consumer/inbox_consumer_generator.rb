# frozen_string_literal: true

require "rails/generators/named_base"
require "generators/kafka_consumer/concerns/configuration"

module KafkaConsumer
  module Generators
    class InboxConsumerGenerator < Rails::Generators::NamedBase
      include Concerns::Configuration

      source_root File.expand_path("templates", __dir__)

      argument :group_name, type: :string, banner: "group.name"
      argument :topics, type: :array, default: [], banner: "topic topic"

      def process_topics
        check_config_file!

        @items = {}
        topics.each do |topic|
          inbox_item = ask "Would you also add an InboxItem class for topic '#{topic}'?" \
                           " Type item's name in the form of SomeModel::InboxItem or press Enter" \
                           " to skip creating item's class"
          @items[topic] = if inbox_item.blank?
            nil
          else
            generate "outbox:item", inbox_item, "--kind inbox"
            inbox_item.classify
          end
        end
      end

      def insert_consumer_group
        insert_into_file CONFIG_PATH, group_template.result(binding), after: "consumer_groups:\n"
      end

      private

      def group_template_path
        File.join(InboxConsumerGenerator.source_root, "consumer_group.yml.erb")
      end

      def group_template
        ERB.new(File.read(group_template_path), trim_mode: "%-")
      end
    end
  end
end
