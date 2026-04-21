class OrdersConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = message.payload.is_a?(Hash) ? message.payload : JSON.parse(message.payload)
      order = Order.find(payload['order_id'])
      order.update!(status: 'processed')
      puts "Processed order #{order.id}"
    end
  rescue => e
    Rails.logger.error("OrdersConsumer error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
