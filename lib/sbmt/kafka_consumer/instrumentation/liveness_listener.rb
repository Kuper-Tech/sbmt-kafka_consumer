# frozen_string_literal: true

module Sbmt
  module KafkaConsumer
    module Instrumentation
      class LivenessListener
        include ListenerHelper
        include KafkaConsumer::Probes::Probe

        ERROR_TYPE = "Liveness probe error"

        def initialize(timeout_sec: 300, max_error_count: 10)
          @timeout_sec = timeout_sec * 1000
          @max_error_count = max_error_count
          @error_count = 0
          @error_backtrace = nil
          @polls = {}
          @mutex = Mutex.new
          setup_subscription
        end

        def probe(_env)
          now = monotonic_now
          has_timed_out_polls = polls.values.any? { |tick| (now - tick) > timeout_sec }

          if !has_timed_out_polls && @error_count < @max_error_count
            probe_ok timed_out_polls: false, errors_count: @error_count
          elsif @error_count >= @max_error_count
            probe_error error_type: ERROR_TYPE, timed_out_polls: false, error_count: @error_count, error_backtrace: @error_backtrace
          else
            probe_error error_type: ERROR_TYPE, timed_out_polls: true, errors_count: @error_count, polls: polls
          end
        end

        def on_connection_listener_fetch_loop(event)
          now = monotonic_now
          KafkaConsumer.logger.debug("on_connection_listener_fetch_loop: now=#{now}, thread_id=#{thread_id}")
          mutex.synchronize do
            polls[thread_id] = monotonic_now
          end
        end

        def on_error_occurred(event)
          type = event[:type]

          return unless type == "librdkafka.error"
          error = event[:error]

          @error_backtrace ||= (error.backtrace || []).join("\n")
          @error_count += 1
        end

        private

        attr_reader :polls, :timeout_sec, :mutex

        def monotonic_now
          ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, :float_millisecond)
        end

        def thread_id
          Thread.current.object_id
        end

        def setup_subscription
          Karafka::App.monitor.subscribe(self)
        end
      end
    end
  end
end
