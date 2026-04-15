class OrdersConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = JSON.parse(message.payload)
      order = Order.find(payload['order_id'])
      order.update!(status: 'processed')
      puts "Processed order #{order.id}"
    end
  end
end
