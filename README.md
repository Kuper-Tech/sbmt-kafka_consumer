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

Создать и настроить конфигурационный файл config/kafka_consumer.yml, пример конфига:
```ruby
default: &default
  client_id: 'some-name'
  auth:
    kind: plaintext
  kafka:
    servers: "kafka:9092"
    rdkafka:
      allow.auto.create.topics: true
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
