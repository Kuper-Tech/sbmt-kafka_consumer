# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class ChainableMonitor < BaseMonitor
        attr_reader :monitors

        def initialize(monitors = [])
          super()

          @monitors = monitors
        end

        def instrument(event_id, payload = EMPTY_HASH, &block)
          return super if monitors.empty?

          chain = monitors.map { |monitor| monitor.new(event_id, payload) }
          traverse_chain = proc do
            if chain.empty?
              super
            else
              chain.shift.trace(&traverse_chain)
            end
          end
          traverse_chain.call
        end
      end
    end
  end
end
