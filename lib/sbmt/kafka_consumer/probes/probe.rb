# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Probes
      module Probe
        HEADERS = {"Content-Type" => "application/json"}.freeze

        def call(env)
          with_error_handler { probe(env) }
        end

        def meta
          {}
        end

        def probe_ok(extra_meta = {})
          [200, HEADERS, [meta.merge(extra_meta).to_json]]
        end

        def probe_error(extra_meta = {})
          [500, HEADERS, [meta.merge(extra_meta).to_json]]
        end

        def with_error_handler
          yield
        rescue => error
          probe_error(error_class: error.class.name, error_message: error.message)
        end
      end
    end
  end
end
