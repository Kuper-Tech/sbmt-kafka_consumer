# frozen_string_literal: true

class TestInboxItemTransport < Sbmt::Outbox::DryInteractor
  option :source

  def call(_inbox_item, _payload)
    Success()
  end
end
