class MarketplaceEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = message.payload.is_a?(Hash) ? message.payload : JSON.parse(message.payload)

      MarketplaceEvent.create!(
        topic: message.topic,
        event_type: message.topic,
        payload: payload
      )

      Rails.logger.info("Stored event from #{message.topic}")
    end
  rescue => e
    Rails.logger.error("MarketplaceEventsConsumer error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
