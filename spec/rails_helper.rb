# frozen_string_literal: true

require "spec_helper"
require "combustion"
require "factory_bot_rails"
require "dry-monads"
require "dry/monads/result"
require "sbmt/kafka_consumer/testing"

begin
  Combustion.initialize! :active_record do
    if ENV["LOG"].to_s.empty?
      config.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))
      config.log_level = :fatal
    else
      config.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
      config.log_level = :debug
    end

    config.i18n.available_locales = %i[ru en]
    config.i18n.default_locale = :ru
  end
rescue => e
  # Fail fast if application couldn't be loaded
  warn "💥 Failed to load the app: #{e.message}\n#{e.backtrace.join("\n")}"
  exit(1)
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }
Dir["#{__dir__}/factories/**/*.rb"].sort.each { |f| require f }

require "sbmt/dev/testing/rails_configuration"
