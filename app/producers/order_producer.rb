class OrderProducer
  def self.call(order)
    Karafka.producer.produce_async(
      topic: 'orders',
      payload: { order_id: order.id, description: order.description }.to_json
    )
  end
end
