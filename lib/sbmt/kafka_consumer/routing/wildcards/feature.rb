# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Routing
      module Wildcards
        class Feature < ::Karafka::Routing::Features::Base
          module ConsumerGroup
            def wildcard=(regexp, &block)
              Contract.new.validate!({regexp: regexp})

              matching_topics = ::Sbmt::KafkaConsumer::Routing::ListExistingTopics.call(regexp)
              raise ::Karafka::Errors::InvalidConfigurationError, "there's no topics matching regexp #{regexp}" if matching_topics.blank?

              matching_topics.each { |topic_name| public_send(:topic=, topic_name, &block) }
            end
          end

          module Builder
            def wildcard(regexp, &block)
              consumer_group(default_group_id) { wildcard(regexp, &block) }
            end
          end
        end
      end
    end
  end
end
