class MarketplaceEventProducer
  def self.call(topic:, payload:)
    Karafka.producer.produce_sync(
      topic: topic,
      payload: payload.to_json
    )

    Rails.logger.info("Published event to #{topic}")
  rescue => e
    Rails.logger.error("Failed to publish #{topic}: #{e.message}")
    raise
  end
end
