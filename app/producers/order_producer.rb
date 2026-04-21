class OrderProducer
  def self.call(order)
    Karafka.producer.produce_sync(
      topic: 'orders',
      payload: { order_id: order.id, description: order.description }.to_json
    )
    Rails.logger.info("Order #{order.id} published to Kafka")
  rescue => e
    Rails.logger.error("Failed to publish order: #{e.message}")
    raise
  end
end
