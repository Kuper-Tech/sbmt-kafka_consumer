# frozen_string_literal: true

require "rails_helper"

describe Sbmt::KafkaConsumer::BaseConsumer do
  include_context "with sbmt karafka consumer"

  let(:consumer_class) do
    Class.new(described_class.consumer_klass) do
      attr_reader :consumed, :consume_count

      def initialize(error: nil, reset_error: true)
        @error = error
        @reset_error = reset_error
        super()
      end

      def process_message(_message)
        @consume_count = @consume_count.to_i + 1

        if @error
          error_to_raise = @error
          @error = nil if @reset_error

          raise error_to_raise, "test error"
        end

        @consumed = true
      end

      def consumed?
        !!@consumed
      end
    end
  end

  let(:consumer) { build_consumer(consumer_class.new) }

  let(:payload) { "test-payload" }
  let(:headers) { {"Test-Header" => "test-header-value"} }
  let(:key) { "test-key" }
  let(:consume_error) { nil }

  before do
    stub_const("Sbmt::KafkaConsumer::BaseConsumer::DEFAULT_RETRY_DELAY_MULTIPLIER", 0)
    allow(consumer).to receive(:log_payload?).and_return(true)
    publish_to_sbmt_karafka(payload.to_json, headers: headers, key: key)
  end

  it "consumes" do
    consume_with_sbmt_karafka
    expect(consumer).to be_consumed
  end

  it "logs message" do
    expect(Rails.logger).to receive(:info).with(/Successfully consumed message/)
    expect(Rails.logger).to receive(:info).with(/Processing message/)
    expect(Rails.logger).to receive(:info).with(/Commit offset/)
    expect(Rails.logger).to receive(:info).with(/#{payload}/)

    consume_with_sbmt_karafka
    expect(consumer).to be_consumed
  end

  context "when get active record error" do
    let(:error) { ActiveRecord::StatementInvalid }
    let(:consumer) { build_consumer(consumer_class.new(error: error)) }

    it "tracks error" do
      allow(Rails.logger).to receive(:error)

      consume_with_sbmt_karafka
      expect(consumer).not_to be_consumed
      expect(consumer.consume_count).to eq 1
    end
  end

  context "when consumer raises exception" do
    let(:consumer_class) do
      base_klass = described_class.consumer_klass(skip_on_error: true)
      Class.new(base_klass) do
        def process_message(_message)
          raise "always throws an exception"
        end
      end
    end
    let(:consumer) { build_consumer(consumer_class.new) }

    it "skips message if skip_on_error is set" do
      expect(Rails.logger).to receive(:error).twice

      consume_with_sbmt_karafka
    end
  end
end
