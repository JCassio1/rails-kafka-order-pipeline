require "test_helper"

class MarketplaceEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    MarketplaceEvent.delete_all

    MarketplaceEvent.create!(
      topic: "user.signed_up",
      event_type: "user.signed_up",
      payload: { user_id: 10, email: "u10@example.com" },
      created_at: 2.hours.ago
    )
    MarketplaceEvent.create!(
      topic: "listing.viewed",
      event_type: "listing.viewed",
      payload: { listing_id: 44, user_id: 10 },
      created_at: 80.minutes.ago
    )
    MarketplaceEvent.create!(
      topic: "order.placed",
      event_type: "order.placed",
      payload: { order_id: "ord-1", user_id: 10, amount_cents: 2599, currency: "GBP" },
      created_at: 30.minutes.ago
    )
    MarketplaceEvent.create!(
      topic: "review.submitted",
      event_type: "review.submitted",
      payload: { review_id: 21, user_id: 10, rating: 5 },
      created_at: 15.minutes.ago
    )
  end

  test "index responds with html" do
    get marketplace_events_url
    assert_response :success
    assert_select "h1", /Real-Time Event Dashboard/
  end

  test "index responds with json snapshot" do
    get marketplace_events_url(format: :json)
    assert_response :success

    payload = JSON.parse(response.body)
    assert payload.key?("feed")
    assert payload.key?("counters")
    assert payload.key?("orders_chart")
    assert payload.key?("topic_distribution")
    assert payload.key?("recent_orders")
    assert payload.key?("user_activity")

    assert_equal 1, payload.dig("counters", "order.placed")
    assert_equal 1, payload.dig("orders_chart", "totals", "orders")
    assert_equal 25.99, payload.dig("orders_chart", "totals", "revenue_gbp")
    assert_equal 1, payload.dig("user_activity", "signups_last_24h")
    assert_equal 1, payload.dig("user_activity", "total_users")
    assert_equal 1, payload["recent_orders"].length
  end
end
