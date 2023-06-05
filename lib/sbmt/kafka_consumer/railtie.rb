# frozen_string_literal: true

require "rails/railtie"

module Sbmt
  module KafkaConsumer
    class Railtie < Rails::Railtie
      initializer "sbmt_kafka_consumer_yabeda.configure_rails_initialization" do
        YabedaConfigurer.configure
      end

      # it must be consistent with sbmt_karafka initializers' name
      initializer "sbmt_kafka_consumer_karafka_init.configure_rails_initialization",
        before: "sbmt_karafka.require_karafka_boot_file" do
        # skip loading native karafka.rb, because we want custom init process
        SbmtKarafka.instance_eval do
          def boot_file; false; end
        end
      end
    end
  end
end
