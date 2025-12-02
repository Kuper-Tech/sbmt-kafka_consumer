# frozen_string_literal: true

class TestGlobalProcessBatchMiddleware
  def call(_message)
    yield
  end
end
