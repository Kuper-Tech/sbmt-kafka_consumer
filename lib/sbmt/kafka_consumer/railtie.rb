# frozen_string_literal: true

require "rails/railtie"

module Sbmt
  module KafkaConsumer
    class Railtie < Rails::Railtie
      initializer "sbmt_kafka_consumer_yabeda.configure_rails_initialization" do
        Yabeda.configure do
          group :kafka_consumer do
            counter :consumes,
              tags: %i[topic partition],
              comment: "Base consumer consumes"

            counter :inbox_consumes,
              tags: %i[inbox_name event_name status],
              comment: "Inbox item consumes"
          end
        end
      end

      # it must be consistent with sbmt_karafka initializers' name
      initializer "sbmt_kafka_consumer_karafka_init.configure_rails_initialization",
        before: "sbmt_karafka.require_karafka_boot_file" do
        # skip loading native karafka.rb, because we want custom init process
        SbmtKarafka.instance_eval do
          def boot_file; false; end
        end
      end

      # it must be consistent with sbmt_karafka initializers' name
      initializer "sbmt_kafka_consumer_instrumentation.configure_rails_initialization",
        after: "sbmt_karafka.require_karafka_boot_file" do |app|
        # for custom rails' versions loading hacks see sbmt_karafka/railtie
        rails6plus = Rails.gem_version >= Gem::Version.new("6.0.0")

        if rails6plus
          app.reloader.to_prepare do
            # Load SbmtKarafka boot file, so it can be used in Rails server context
            AppInitializer.initialize!
          end
        else
          # Load SbmtKarafka main setup for older Rails versions
          app.config.after_initialize do
            AppInitializer.initialize!
          end
        end
      end
    end
  end
end
