# Sbmt::KafkaConsumer

Гем для консюминга сообщений из kafka
- 
- представляет собой абстракцию над используемым кафка-клиентом (на данный момент это karafka 2)
- предоставляет более удобное конфигурирование консюмеров, а также возможность использования [Inbox Pattern](https://gitlab.sbmt.io/paas/rfc/-/tree/master/text/paas-2597-inbox) из коробки совместно с гемом [Outbox](https://gitlab.sbmt.io/nstmrt/rubygems/outbox)

## Подключение и конфигурация

Добавить в Gemfile
```ruby
gem "sbmt-kafka_consumer", "~> 0.1.0"
```

Выполнить
```shell
bundle install
```

Создать и настроить конфигурационный файл config/kafka_consumer.yml, пример (см. описание параметров ниже):
```ruby
default: &default
  client_id: 'some-name'
  max_wait_time: 1
  shutdown_timeout: 60
  concurrency: 5
  pause_timeout: 1
  pause_max_timeout: 30
  pause_with_exponential_backoff: true
  auth:
    kind: plaintext
  kafka:
    servers: "kafka:9092"
    heartbeat_timeout: 5
    session_timeout: 30
    reconnect_timeout: 3
    connect_timeout: 5
    socket_timeout: 30
    kafka_options:
      allow.auto.create.topics: true
  consumer_groups:
    group_ref_id_1:
      name: cg_with_single_topic
      topics:
        - name: topic_with_inbox_items
          consumer:
            klass: "Sbmt::KafkaConsumer::InboxConsumer"
            init_attrs:
              name: "test_items"
              inbox_item: "TestInboxItem"
          deserializer:
            klass: "Sbmt::KafkaConsumer::Serialization::NullDeserializer"
    group_ref_id_2:
      name: cg_with_multiple_topics:
      topics:
        - name: topic_with_json_data
          consumer:
            klass: "SimpleLoggingConsumer"
          deserializer:
            klass: "Sbmt::KafkaConsumer::Serialization::JsonDeserializer"
        - name: topic_with_protobuf_data
          consumer:
            klass: "SimpleLoggingConsumer"
          deserializer:
            klass: "Sbmt::KafkaConsumer::Serialization::ProtobufDeserializer"
            init_attrs:
              message_decoder_klass: "Sso::UserRegistration"
              skip_decoding_error: true

development:
  <<: *default
test:
  <<: *default
  deliver: false
staging: &staging
  <<: *default
production:
  <<: *staging

```

#### Конфигурация: блок `auth`

Поддерживаются две версии: plaintext (дефолт, если не указывать) и SASL-plaintext

Вариант конфигурации SASL-plaintext:
```ruby
...
  auth:
    kind: sasl_plaintext
    sasl_username: user
    sasl_password: pwd
    sasl_mechanism: SCRAM-SHA-512
...
```

#### Конфигурация: блок `kafka`

Обязательной опцией является `servers` в формате rdkafka (без префикса схемы `kafka://`): `srv1:port1,srv2:port2,...`
В разделе `kafka_options` можно указать (любые опции rdkafka)[https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md]

#### Конфигурация: блок `consumer_groups`

```ruby
...
  consumer_groups:
    # id нужно использовать при запуске процесса консюмера (см. ниже раздел CLI)
    id_группы:
      name: имя_группы
      topics:
      - name: имя_топика
        consumer:
          klass: [required] класс консюмера, отнаследованный от BaseConsumer
          init_attrs:
            # [optional] атрибуты которые будут переданы в конструктор при инициализации инстанса класса консюмера
            key: value
        deserializer:
          klass: [optional] класс десериалайзера, отнаследованный от BaseDeserializer, по умолчанию используется NullDeserializer 
          init_attrs:
            # [optional] атрибуты которые будут переданы в конструктор при инициализации инстанса класса десериалайзера
            key: value
...
```

#### Конфигурация: env-файл `Kafkafile`

Также существует возможность дополнительной конфигурации окружения с помощью `Kafkafile`, может быть удобно для
- конфигурации readiness/liveness проб
- конфигурации экспортера метрик

Пример `Kafkafile`:
```ruby
# frozen_string_literal: true

require_relative "config/environment"

Thread.new do
  ::Rack::Handler::WEBrick.run(
    ::Rack::Builder.new do
      use ::Yabeda::Prometheus::Exporter if defined?(Yabeda)
      run health_check_app
    end,
    Host: '0.0.0.0',
    Port: ENV.fetch('PROMETHEUS_EXPORTER_PORT', '9394')
  )
end

```

P.S. файл должен находиться в корне Rails-проекта

#### Метрики

Гем собирает базовые метрики консюминга в yabeda, см. `YabedaConfigurer`
Для начала работы достаточно в основном приложении подключить любой поддерживаемый yabeda-экспортер (например, `yabeda-prometheus-mmap`) и метрики станут доступны из коробки

## CLI

Запуск сервера

```shell
$ bundle exec kafka_consumer -g id_группы_1 -g id_группы_2 -c 10
```

Где:
- `-g` - `group`, идентификатор консюмер-группы, если не указывать - будут запущены все группы из конфига
- `-c` - `concurrency`, кол-во воркеров (на весь процесс), по умолчанию 5 (дефолт karafka)

В `karafka v2` было проделано много работы в плане многопоточности (см. [Concurrency and Multithreading](https://karafka.io/docs/Concurrency-and-multithreading/))
Параметр `concurrency` необходимо выбрать опытным путем, исходя из:
- суммы партиций всех топиков (равно или кратно меньше / пропорционально кол-ву подов), обрабатываемых в рамках 1 процесса `kafka_consumer`
- не забывать о нагрузке на БД при большом кол-ве потоков и интенсивности сообщений в топике

P.S. `config/kafka_consumer.yml` обязателен для запуска

## Разработка

### Локальное окружение

1. Подготовка рабочего окружения
```shell
dip provision
```

2. Запуск тестов
```shell
dip rspec
```

3. Запуск сервера
```shell
dip up
```
