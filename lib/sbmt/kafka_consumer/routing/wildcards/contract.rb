# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Routing
      module Wildcards
        class Contract < ::Karafka::Contracts::Base
          configure do |config|
            config.error_messages = {"regexp_format" => "must be a non-empty regular expression"}

            required(:regexp) { _1.is_a?(Regexp) && !_1.source.empty? }
          end
        end
      end
    end
  end
end
