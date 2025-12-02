# frozen_string_literal: true

class TestGlobalProcessMessageMiddleware
  def call(_message)
    yield
  end
end
