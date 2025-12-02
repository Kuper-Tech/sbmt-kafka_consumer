# frozen_string_literal: true

require "rails_helper"

class MyMiddleware
  def call(message)
    yield
  end
end

class MyMiddleware1
  def call(message)
    yield
  end
end

class SkipMessageMiddleware
  def call(message); end
end

class MiddlewareError
  def call(message)
    raise exception_class, "Middleware error"
  end
end

class MyMiddlewareWithTwoParams
  def call(message, consumer)
    yield
  end
end

describe Sbmt::KafkaConsumer::BaseConsumer do
  include_context "with sbmt karafka consumer"

  context "with class_attribute params" do
    it "child class does not overwrite parent's attrs" do
      parent_class = described_class.consumer_klass(skip_on_error: false)
      expect(parent_class.skip_on_error).to be(false)
      expect(parent_class.name).to eq(described_class.name)

      child_class = parent_class.consumer_klass(skip_on_error: true)
      expect(child_class.skip_on_error).to be(true)
      expect(child_class.name).to eq(described_class.name)

      expect(parent_class.skip_on_error).to be(false)
    end
  end

  context "when the consumer processes one message at a time" do
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

    it "calls global middlewares" do
      expect_any_instance_of(TestGlobalProcessMessageMiddleware).to receive(:call).and_call_original
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

      it "skips message if skip_on_error is set" do
        expect(Rails.logger).to receive(:error).twice

        consume_with_sbmt_karafka
      end
    end

    context "when cooperative_sticky is true" do
      before do
        allow(consumer).to receive(:cooperative_sticky?).and_return(true)
      end

      it "calls mark_as_consumed" do
        expect(consumer).to receive(:mark_as_consumed).once.and_call_original
        expect(consumer).not_to receive(:mark_as_consumed!)

        consume_with_sbmt_karafka
      end
    end

    context "when cooperative_sticky is false" do
      before do
        allow(consumer).to receive(:cooperative_sticky?).and_return(false)
      end

      it "calls mark_as_consumed!" do
        expect(consumer).to receive(:mark_as_consumed!).once.and_call_original
        expect(consumer).not_to receive(:mark_as_consumed)

        consume_with_sbmt_karafka
      end
    end

    context "when used middlewares" do
      let(:consumer_class) do
        base_klass = described_class.consumer_klass(middlewares: middlewares)
        Class.new(base_klass) do
          def process_message(_message)
            @consumed = true
          end

          def consumed?
            !!@consumed
          end
        end
      end

      context "when middleware condition calls message processing" do
        let(:middlewares) { ["SkipMessageMiddleware"] }

        it "calls middleware before processing message" do
          expect(consumer).not_to receive(:process_message)
          expect(consumer).to receive(:mark_message).once.and_call_original

          consume_with_sbmt_karafka
          expect(consumer).not_to be_consumed
        end
      end

      context "when middlewares are present" do
        let(:middlewares) { ["MyMiddleware"] }

        it "calls middleware before processing message" do
          consume_with_sbmt_karafka
          expect(consumer).to be_consumed
        end
      end

      context "when multiple middlewares are present" do
        let(:middlewares) { %w[MyMiddleware MyMiddleware1] }

        it "calls each middleware in order before processing message" do
          consume_with_sbmt_karafka
          expect(consumer).to be_consumed
        end
      end

      context "when no middlewares are present" do
        let(:consumer_class) do
          Class.new(described_class.consumer_klass) do
            def process_message(_message)
              @consumed = true
            end

            def consumed?
              !!@consumed
            end
          end
        end

        it "does not call any middleware" do
          consume_with_sbmt_karafka
          expect(consumer).to be_consumed
        end
      end

      context "when middleware raises exception" do
        let(:exception_class) { StandardError }
        let(:middlewares) { ["MiddlewareError"] }
        let(:consumer_class) do
          Class.new(described_class.consumer_klass(skip_on_error: true, middlewares: middlewares)) do
            def process_message(_message)
              @consumed = true
            end

            def consumed?
              !!@consumed
            end
          end
        end

        it "skips message if middleware raises exception and skip_on_error is set" do
          expect(Rails.logger).to receive(:warn).once.with(/skipping unprocessable message/)

          consume_with_sbmt_karafka
          expect(consumer).not_to be_consumed
        end
      end

      context "when middleware takes two params" do
        let(:middlewares) { %w[MyMiddleware MyMiddlewareWithTwoParams] }

        it "calls middlewares" do
          consume_with_sbmt_karafka
          expect(consumer).to be_consumed
        end
      end

      context "with global middlewares" do
        let(:middlewares) { ["MyMiddleware"] }

        it "calls middlewares before processing message" do
          expect_any_instance_of(TestGlobalProcessMessageMiddleware).to receive(:call).and_call_original
          expect_any_instance_of(MyMiddleware).to receive(:call).and_call_original
          consume_with_sbmt_karafka
          expect(consumer).to be_consumed
        end
      end
    end
  end

  context "when the consumer export messages in batches" do
    let(:consumer_class) do
      Class.new(described_class.consumer_klass) do
        attr_reader :consumed
        def process_batch(messages)
          Rails.logger.info "Process batch #{messages.count} messages"
          @consumed = true
        end

        def consumed?
          !!@consumed
        end
      end
    end

    let(:payload) { "test-payload" }

    before do
      allow(Rails.logger).to receive(:info)
      publish_to_sbmt_karafka(payload.to_json)
    end

    it "consumes" do
      consume_with_sbmt_karafka
      expect(consumer).to be_consumed
      expect(Rails.logger).to have_received(:info).with(/Process batch/)
    end

    it "calls global middlewares" do
      expect_any_instance_of(TestGlobalProcessBatchMiddleware).to receive(:call).and_call_original
      consume_with_sbmt_karafka
      expect(consumer).to be_consumed
    end

    context "when used middlewares" do
      let(:consumer_class) do
        base_klass = described_class.consumer_klass(middlewares: middlewares, batch_middlewares: batch_middlewares)
        Class.new(base_klass) do
          def process_batch(_messages)
            @consumed = true
          end

          def consumed?
            !!@consumed
          end
        end
      end
      let(:middlewares) { [] }

      context "when middlewares are present" do
        let(:batch_middlewares) { ["MyMiddleware"] }

        it "calls middleware before processing messages" do
          consume_with_sbmt_karafka
          expect(consumer).to be_consumed
        end
      end

      context "when middleware takes two params" do
        let(:batch_middlewares) { %w[MyMiddleware MyMiddlewareWithTwoParams] }

        it "calls middlewares" do
          consume_with_sbmt_karafka
          expect(consumer).to be_consumed
        end
      end

      context "with global middlewares" do
        let(:batch_middlewares) { ["MyMiddleware"] }

        it "calls middlewares before processing message" do
          expect_any_instance_of(TestGlobalProcessBatchMiddleware).to receive(:call).and_call_original
          expect_any_instance_of(MyMiddleware).to receive(:call).and_call_original
          consume_with_sbmt_karafka
          expect(consumer).to be_consumed
        end
      end

      context "with both types of middlewares" do
        let(:batch_middlewares) { ["MyMiddleware"] }
        let(:middlewares) { ["MyMiddleware1"] }

        it "calls only batch middlewares" do
          expect_any_instance_of(MyMiddleware).to receive(:call).and_call_original
          expect_any_instance_of(MyMiddleware1).not_to receive(:call)
          consume_with_sbmt_karafka
          expect(consumer).to be_consumed
        end
      end
    end
  end
end
