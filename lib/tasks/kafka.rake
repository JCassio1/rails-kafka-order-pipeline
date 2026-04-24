namespace :kafka do
  desc "Seed marketplace events into Kafka"
  task seed_events: :environment do
    events = [
      {
        topic: "user.signed_up",
        payload: { user_id: 101, email: "user101@example.com", plan: "starter" }
      },
      {
        topic: "listing.viewed",
        payload: { listing_id: 2001, user_id: 101, source: "search" }
      },
      {
        topic: "order.placed",
        payload: { order_id: 3001, user_id: 101, amount_cents: 2599, currency: "GBP" }
      },
      {
        topic: "review.submitted",
        payload: { review_id: 4001, user_id: 101, listing_id: 2001, rating: 5 }
      }
    ]

    events.each do |event|
      MarketplaceEventProducer.call(topic: event[:topic], payload: event[:payload])
      puts "Published #{event[:topic]}"
    end

    puts "Done. Published #{events.size} events."
  end
end
