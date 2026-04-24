class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { 'bootstrap.servers': ENV.fetch('KAFKA_BROKERS', 'kafka:29092') }
    config.client_id = 'event_app'
    config.strict_topics_namespacing = false
  end

  routes.draw do
    consumer_group :marketplace_events_group do
      topic "user.signed_up" do
        consumer MarketplaceEventsConsumer
      end

      topic "listing.viewed" do
        consumer MarketplaceEventsConsumer
      end

      topic "order.placed" do
        consumer MarketplaceEventsConsumer
      end

      topic "review.submitted" do
        consumer MarketplaceEventsConsumer
      end
    end
  end
end
