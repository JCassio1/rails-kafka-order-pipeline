class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { 'bootstrap.servers': ENV.fetch('KAFKA_BROKERS', 'kafka:29092') }
    config.client_id = 'event_app'
  end

  routes.draw do
    consumer_group :orders_group do
      topic :orders do
        consumer OrdersConsumer
      end
    end
  end
end