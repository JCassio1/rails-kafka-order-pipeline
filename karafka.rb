class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { 'bootstrap.servers': 'localhost:9092' }
    config.client_id = 'event_app'
  end

  routes.draw do
    topic :orders do
      consumer OrdersConsumer
    end
  end
end