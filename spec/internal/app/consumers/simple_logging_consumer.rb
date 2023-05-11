# frozen_string_literal: true

class SimpleLoggingConsumer < Sbmt::KafkaConsumer::BaseConsumer
  private

  def log_payload?
    true
  end

  def process_message(_message); end
end
