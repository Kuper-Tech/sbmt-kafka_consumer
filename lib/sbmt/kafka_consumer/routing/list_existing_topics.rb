# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Routing
      class ListExistingTopics
        class_attribute :cached_cluster_topics, instance_writer: false, default: nil

        def self.call(regexp)
          return cached_cluster_topics.grep(regexp) if cached_cluster_topics.present?

          ::Karafka::Admin
            .cluster_info
            .topics
            .map { |topic| topic.fetch(:topic_name) }
            .grep(regexp)
        end
      end
    end
  end
end
