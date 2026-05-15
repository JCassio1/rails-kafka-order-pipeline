namespace :kafka do
  desc "Seed realistic marketplace events into Kafka (use EVENTS, DELAY_MS, USER_POOL, LISTING_POOL env vars)"
  task seed_events: :environment do
    require "timeout"
    $stdout.sync = true

    total_events = ENV.fetch("EVENTS", "120").to_i.clamp(1, 10_000)
    delay_seconds = (ENV.fetch("DELAY_MS", "25").to_i.clamp(0, 5_000) / 1000.0)
    user_pool_size = ENV.fetch("USER_POOL", "80").to_i.clamp(5, 20_000)
    listing_pool_size = ENV.fetch("LISTING_POOL", "160").to_i.clamp(10, 50_000)
    publish_timeout_seconds = ENV.fetch("PUBLISH_TIMEOUT", "10").to_i.clamp(2, 60)

    user_ids = (10_001...(10_001 + user_pool_size)).to_a
    listing_ids = (20_001...(20_001 + listing_pool_size)).to_a
    known_users = []
    topic_counts = Hash.new(0)
    total_revenue_cents = 0
    order_id = 30_000
    review_id = 40_000

    weighted_topics = [
      [ "listing.viewed", 40 ],
      [ "order.placed", 30 ],
      [ "user.signed_up", 20 ],
      [ "review.submitted", 10 ]
    ].freeze

    plan_tiers = %w[starter pro business].freeze
    signup_sources = %w[organic ad_campaign referral social].freeze
    listing_sources = %w[search recommendations home_feed email].freeze
    order_statuses = %w[pending processed failed refunded].freeze
    review_comments = [
      "Fast delivery and great quality",
      "Exactly as described",
      "Would buy again",
      "Packaging could be better",
      "Great value for money"
    ].freeze

    pick_topic = lambda do
      target = rand(1..100)
      running = 0
      weighted_topics.each do |name, weight|
        running += weight
        return name if target <= running
      end
      weighted_topics.first.first
    end

    total_events.times do |index|
      topic = pick_topic.call
      user_id = known_users.sample || user_ids.sample
      payload = {}

      case topic
      when "user.signed_up"
        user_id = user_ids.sample
        known_users << user_id unless known_users.include?(user_id)
        payload = {
          user_id: user_id,
          email: "user#{user_id}@example.com",
          plan: plan_tiers.sample,
          source: signup_sources.sample
        }
      when "listing.viewed"
        payload = {
          listing_id: listing_ids.sample,
          user_id: user_id,
          source: listing_sources.sample
        }
      when "order.placed"
        order_id += 1
        amount_cents = rand(1_100..45_000)
        total_revenue_cents += amount_cents
        payload = {
          order_id: order_id,
          user_id: user_id,
          amount_cents: amount_cents,
          currency: "GBP",
          status: order_statuses.sample
        }
      when "review.submitted"
        review_id += 1
        payload = {
          review_id: review_id,
          user_id: user_id,
          listing_id: listing_ids.sample,
          rating: rand(3..5),
          comment: review_comments.sample
        }
      end

      puts "Publishing #{index + 1}/#{total_events} -> #{topic}"
      Timeout.timeout(publish_timeout_seconds) do
        MarketplaceEventProducer.call(topic: topic, payload: payload)
      end
      topic_counts[topic] += 1

      if ((index + 1) % 20).zero? || index == total_events - 1
        puts "Published #{index + 1}/#{total_events} events..."
      end

      sleep(delay_seconds) if delay_seconds.positive?
    rescue Timeout::Error
      warn "Timed out publishing event #{index + 1} after #{publish_timeout_seconds}s. Check Kafka connectivity."
      raise
    end

    puts "Done. Published #{total_events} events."
    puts "Topic distribution:"
    topic_counts.each do |topic, count|
      puts "  - #{topic}: #{count}"
    end
    puts format("Estimated revenue from order.placed: £%.2f", total_revenue_cents / 100.0)
  end
end
