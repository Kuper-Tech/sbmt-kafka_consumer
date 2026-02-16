# frozen_string_literal: true

require_relative "../../app/middlewares/test_global_process_message_middleware"
require_relative "../../app/middlewares/test_global_process_batch_middleware"

Sbmt::KafkaConsumer.process_message_middlewares.push(
  TestGlobalProcessMessageMiddleware
)

Sbmt::KafkaConsumer.process_batch_middlewares.push(
  TestGlobalProcessBatchMiddleware
)
