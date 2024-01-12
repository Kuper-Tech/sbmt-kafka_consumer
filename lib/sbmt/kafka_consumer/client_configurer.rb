# frozen_string_literal: true

class Sbmt::KafkaConsumer::ClientConfigurer
  def self.configure!(**opts)
    config = Sbmt::KafkaConsumer::Config.new
    SbmtKarafka::App.setup do |karafka_config|
      karafka_config.monitor = config.monitor_class.classify.constantize.new
      karafka_config.logger = Sbmt::KafkaConsumer.logger
      karafka_config.deserializer = config.deserializer_class.classify.constantize.new

      karafka_config.client_id = config.client_id
      karafka_config.consumer_mapper = config.consumer_mapper_class.classify.constantize.new
      karafka_config.kafka = config.to_kafka_options

      karafka_config.pause_timeout = config.pause_timeout * 1_000 if config.pause_timeout.present?
      karafka_config.pause_max_timeout = config.pause_max_timeout * 1_000 if config.pause_max_timeout.present?
      karafka_config.max_wait_time = config.max_wait_time * 1_000 if config.max_wait_time.present?
      karafka_config.shutdown_timeout = config.shutdown_timeout * 1_000 if config.shutdown_timeout.present?

      karafka_config.pause_with_exponential_backoff = config.pause_with_exponential_backoff if config.pause_with_exponential_backoff.present?

      karafka_config.concurrency = (opts[:concurrency]) || config.concurrency

      # Do not validate topics naming consistency
      # see https://github.com/karafka/karafka/wiki/FAQ#why-am-i-seeing-a-needs-to-be-consistent-namespacing-style-error
      karafka_config.strict_topics_namespacing = false

      # Recreate consumers with each batch. This will allow Rails code reload to work in the
      # development mode. Otherwise SbmtKarafka process would not be aware of code changes
      karafka_config.consumer_persistence = !Rails.env.development?
    end

    SbmtKarafka.monitor.subscribe(config.logger_listener_class.classify.constantize.new)
    SbmtKarafka.monitor.subscribe(config.metrics_listener_class.classify.constantize.new)

    target_consumer_groups = if opts[:consumer_groups].blank?
      config.consumer_groups
    else
      config.consumer_groups.select do |group|
        opts[:consumer_groups].include?(group.id)
      end
    end

    raise "No configured consumer groups found, exiting" if target_consumer_groups.blank?

    # clear routes in case CLI runner tries to reconfigure them
    # but railtie initializer had already executed and did the same
    # otherwise we'll get duplicate routes error from sbmt-karafka internal config validation process
    SbmtKarafka::App.routes.clear
    SbmtKarafka::App.routes.draw do
      target_consumer_groups.each do |cg|
        consumer_group cg.name do
          cg.topics.each do |t|
            topic t.name do
              active t.active
              manual_offset_management t.manual_offset_management
              consumer t.consumer.consumer_klass
              deserializer t.deserializer.instantiate if t.deserializer.klass.present?
              kafka t.kafka_options if t.kafka_options.present?
            end
          end
        end
      end
    end
  end

  def self.routes
    SbmtKarafka::App.routes.map do |cg|
      topics = cg.topics.map { |t| {name: t.name, deserializer: t.deserializer} }
      {group: cg.id, topics: topics}
    end
  end
end
