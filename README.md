# Sbmt::KafkaConsumer

Гем для консюминга сообщений из kafka
- 
- представляет собой абстракцию над используемым кафка-клиентом (на данный момент это karafka 2)
- предоставляет более удобное конфигурирование консюмеров, а также возможность использования [Inbox Pattern](https://gitlab.sbmt.io/paas/rfc/-/tree/master/text/paas-2597-inbox) из коробки совместно с гемом [Outbox](https://gitlab.sbmt.io/nstmrt/rubygems/outbox)

## Подключение и конфигурация

Добавить в Gemfile
```ruby
gem "sbmt-kafka_consumer", "~> 0.14.0"
```

Выполнить
```shell
bundle install
```

Создать и настроить конфигурационный файл config/kafka_consumer.yml.
Для быстрой настройки см. раздел [Генераторы](#генераторы). Пример (см. описание в разделах ниже):
```yaml
default: &default
  client_id: 'some-name' # значение параметра крайне важно при миграции на существующую консюмер-группу, см. раздел ниже
  max_wait_time: 1
  shutdown_timeout: 60
  concurrency: 4 # см. раздел ниже о настройке производительности
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
      name: cg_with_multiple_topics
      topics:
        - name: topic_with_json_data
          consumer:
            klass: "Sbmt::KafkaConsumer::SimpleLoggingConsumer"
          deserializer:
            klass: "Sbmt::KafkaConsumer::Serialization::JsonDeserializer"
        - name: topic_with_protobuf_data
          consumer:
            klass: "Sbmt::KafkaConsumer::SimpleLoggingConsumer"
          deserializer:
            klass: "Sbmt::KafkaConsumer::Serialization::ProtobufDeserializer"
            init_attrs:
              message_decoder_klass: "Sso::UserRegistration"
              skip_decoding_error: true
  probes:
    port: 9394
    endpoints:
      liveness:
        enabled: true
        timeout: 15
      readiness:
        enabled: true
        path: "/readiness/kafka_consumer"

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

## Генераторы

Для упрощения первоначальной настройки и создания consumer реализованы rails-генераторы

### Настройка первоначальной конфигурации гема

Базовая конфигурация:

```shell
bundle exec rails g kafka_consumer:install
```

### Создание не-инбокс консюмера

```shell
bundle exec rails g kafka_consumer:consumer MaybeNamespaced::Name
```

### Создание консюмер группы

```shell
bundle exec rails g kafka_consumer:consumer_group group_key group_name [topic topic...]
```

В `config/kafka_consumer.yml` будет настроена группа и консюмер (InboxConsumer по умолчанию).

#### Конфигурация: `client_id`

**ВАЖНО: при миграции на существующую консюмер-группу необходимо, чтобы ее название не изменилось**

##### При миграции с karafka v1

`Karafka v1` собирает имя консюмер-группы как:

```ruby
"#{client_id.underscored}_#{consumer_group_name}"
```

В данном геме мы сделали поддержку обратной совместимости именования консюмер-групп, поэтому, если необходимо использовать старую группу при миграции, в kafka_consumer.yml допустимо указывать следующие варианты:
- аналогичный `client_id` из `karafka.rb`
- underscored `client_id` из `karafka.rb`, **мы рекомендуем этот вариант**, т.к. в метриках будет возможность легко отличить старый клиент от нового

P.S. в примерах ниже консюмер-группа будет называться `shp_app_НАЗВАНИЕ-ГРУППЫ`

Примеры:

```ruby
# karafka.rb

class KarafkaApp < Karafka::App
  ...

  setup do |config|
    config.client_id = 'shp-app'
	...
  end

  consumer_groups.draw do
    consumer_group НАЗВАНИЕ-ГРУППЫ do
      ...
    end
  end

  ...
end
```

##### При миграции с karafka v2

В этом случае нужно использовать оригинальный client_id, который был указан в karafka.rb (нельзя заменять дефисы на подчеркивания как в примерах выше)
Так сделано потому, что `Karafka v2` собирает имя консюмер-группы как:

```ruby
"#{client_id}_#{consumer_group_name}"
```

т.е. не делает client_id.underscore

Пример:

```yaml
# kafka_consumer.yml

default: &default
  # исходное название из karafka.rb
  client_id: shp-app
  
  # mapper нужно указывать V2 (по умолчанию V1, т.е. предполагается что переходим с karafka v1)
  consumer_mapper_class: "::Sbmt::KafkaConsumer::Routing::KarafkaV2ConsumerMapper"
  ...
  consumer_groups:
    stf_orders:
      name: НАЗВАНИЕ-ГРУППЫ
  ...
```

#### Конфигурация: блок `auth`

Поддерживаются две версии: plaintext (дефолт, если не указывать) и SASL-plaintext

Вариант конфигурации SASL-plaintext:
```yaml
...
  auth:
    kind: sasl_plaintext
    sasl_username: user
    sasl_password: pwd
    sasl_mechanism: SCRAM-SHA-512
...
```

#### Конфигурация: блок `kafka`

Обязательной опцией является `servers` в формате rdkafka (**без префикса схемы** `kafka://`): `srv1:port1,srv2:port2,...`
В разделе `kafka_options` можно указать (любые опции rdkafka)[https://github.com/confluentinc/librdkafka/blob/master/CONFIGURATION.md]

#### Конфигурация: блок `consumer_groups`

```yaml
...
  consumer_groups:
    # id нужно использовать при запуске процесса консюмера (см. ниже раздел CLI)
    id_группы:
      name: имя_группы # [required]
      topics:
      - name: имя_топика # [required]
        active: true # [optional] консюминг топика включен, по умолчанию true
        consumer:
          klass: SomeConsumerClass # [required] класс консюмера, отнаследованный от BaseConsumer
          init_attrs: # [optional] параметры класса консюмера, см. ниже
            key: value
        deserializer:
          klass: [optional] класс десериалайзера, отнаследованный от BaseDeserializer, по умолчанию используется NullDeserializer 
          init_attrs: # [optional] параметры десериалайзера, см. ниже
            key: value
...
```

##### Опции консюмера `BaseConsumer` (`init_attrs`):
- `skip_on_error` - пропускать ошибки обработки, т.е. коммитать оффсеты в случае эксепшенов в бизнес-коде (по умолчанию `false`)

##### Опции консюмера `InboxConsumer` (`init_attrs`):
- `name` - имя класса консюмера (создается динамически)
- `inbox_item` - имя класса InboxItem
- `event_name` - имя события, если в outbox используется несколько типов в рамках одного item (по умолчанию `nil`)
- `skip_on_error` - пропускать ошибки обработки, т.е. коммитать оффсеты в случае исключений в бизнес-коде (по умолчанию `false`)


##### Пример конфигурации inbox-консюмера:
```yaml
  ...
  consumer_groups:
    stf_orders:
      name: <%= ENV.fetch('SHP__KAFKA__ORDERS_CONSUMER_GROUP_NAME'){ 'outbox-orders' } %><%= ENV.fetch('SHP__KAFKA__CONSUMER_GROUP_SUFFIX'){ '' } %>
      topics:
      - name: <%= ENV.fetch('SHP__KAFKA__TOPICS__STF_ORDERS'){ 'yc.customer.fct.orders.0' } %>
        consumer:
          klass: "Sbmt::KafkaConsumer::InboxConsumer"
          init_attrs:
            name: 'orders'
            inbox_item: 'Order::InboxItem'
        # deserializer не задан, т.к. по умолчанию используется NullDeserializer, а для inbox именно это и нужно
  ...
```

##### Пример конфигурации protobuf-консюмера:
```yaml
  ...
  consumer_groups:
    locator:
      name: <%= ENV.fetch('SHP__KAFKA__LOCATOR_CONSUMER_GROUP_NAME'){ 'locator' } %><%= ENV.fetch('SHP__KAFKA__CONSUMER_GROUP_SUFFIX'){ '' } %>
      topics:
      - name: <%= ENV.fetch('SHP__KAFKA__TOPICS__PAAS_LOCATOR_SHOPPER_LOCATIONS') { 'paas-content-operations-norns.save-location' } %>
        consumer:
          klass: "Locator::ShopperLocationConsumer"
          init_attrs:
            skip_on_error: true
        deserializer:
          klass: "Sbmt::KafkaConsumer::Serialization::ProtobufDeserializer"
          init_attrs:
            message_decoder_klass: "Paas::Locator::EventAddLocation"
            skip_decoding_error: true
  ...
```

##### Пример конфигурации json-консюмера:
```yaml
  ...
  consumer_groups:
    jsondata:
      name: json-consumer
      topics:
      - name: json-topic
        consumer:
          klass: "SomeJsonConsumerClass"
          init_attrs:
            skip_on_error: true
        deserializer:
          klass: "Sbmt::KafkaConsumer::Serialization::JsonDeserializer"
          init_attrs:
            skip_decoding_error: true
  ...
```

#### Конфигурация: блок `probes`

```yaml
...
  probes:
    port: порт для старта http_health_check-сервера, по умолчанию 9394
    endpoints:
      liveness:
        enabled: включение/выключение пробы (true/false), по умолчанию true
        path: путь на сервере, по умолчанию "/liveness"
        timeout: таймаут (в секундах), при превышении которого считать группу "мёртвой", по умолчанию 10
      readiness:
        enabled: включение/выключение пробы (true/false), по умолчанию true
        path: путь на сервере, по умолчанию "/readiness/kafka_consumer"
...
```

#### Конфигурация: env-файл `Kafkafile`

Также существует возможность дополнительной конфигурации окружения с помощью `Kafkafile`.

Пример `Kafkafile`:
```ruby
# frozen_string_literal: true

require_relative "config/environment"

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
- `-c` - `concurrency`, кол-во воркеров (на весь процесс), по умолчанию 4, см. ниже

### Настройка параметра `concurrency` 

В `karafka v2` было проделано много работы в плане многопоточности (см. [Concurrency and Multithreading](https://karafka.io/docs/Concurrency-and-multithreading/))

По умолчанию данный параметр глобально равен 4, это означает, что на один экземпляр сервера консюмера (CLI) будет создан thread-пул из 4 воркеров
Данное значение выбрано как компромиссный вариант, которого должно быть достаточно в большинстве кейсов.

Однако, если нужна более тонкая настройка, то нужно учитывать следующие моменты:

#### Корректно расчитать и задать размер пула коннектов ActiveRecord 
- каждый воркер будет стабильно потреблять 1 коннект из пула, т.е. минимальный размер пула должен быть не менее 4
- при использовании sentry в sentry-rails воркеры могут использовать коннект из пула при сериализации моделей, это 1-2 коннекта из пула дополнительно
- в sbmt-app / некоторых приложениях используется периодическая проверка доступности БД (см. `check_db`), которая также может забирать коннект из пула

Например, для concurrency=4 в шоппере оптимальное значение размера пула ActiveRecord для каждого консюмера: 6-8

#### Корректно расчитать кол-во реплик консюмеров
- `КОЛИЧЕСТВО_РЕПЛИК x concurrency` для топиков средней/высокой интенсивностью данных должно быть равно/больше кол-ву партиций потребляемого топика
- `КОЛИЧЕСТВО_РЕПЛИК x concurrency` для топиков с низкой интенсивностью данных может быть меньше кол-ва партиций потребляемого топика
- учитывать кол-во коннектов к БД с учетом кол-ва реплик и раздела про пул коннектов выше, чтобы не превысить лимит по кол-ву подключений

Все вышеупомянутые моменты, конечно, не панацея, для проверки/уточнения их на практике нужно проводить нагрузочное тестирование. Особенно актуально для топиков с большим кол-вом / интенсивностью данных

P.S. если используется combined-pod с консюмерами (см. karafka-combined в STF), потребляющими все/несколько топиков и разными консюмер-группами, concurrency и размер пула нужно подбирать индивидуально

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

3. Rubocop
```shell
dip rubocop
```

4. Запуск сервера
```shell
dip up
```

5. Запустить сервер консюмера
```shell
dip kafka-consumer
```
