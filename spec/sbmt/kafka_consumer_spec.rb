# frozen_string_literal: true

RSpec.describe Sbmt::KafkaConsumer do
  it "has a version number" do
    expect(Sbmt::KafkaConsumer::VERSION).not_to be_nil
  end
end
