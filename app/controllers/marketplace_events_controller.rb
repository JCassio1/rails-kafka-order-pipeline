class MarketplaceEventsController < ApplicationController
  TOPICS = %w[user.signed_up listing.viewed order.placed review.submitted].freeze

  def index
    snapshot = dashboard_snapshot
    @snapshot = snapshot

    respond_to do |format|
      format.html
      format.json { render json: snapshot }
    end
  end

  private

  def dashboard_snapshot
    recent_events = MarketplaceEvent.where(topic: TOPICS).order(created_at: :desc).limit(50)
    counters_by_topic = MarketplaceEvent.where(topic: TOPICS).group(:topic).count
    orders = MarketplaceEvent.where(topic: "order.placed").order(created_at: :desc)
    signup_events = MarketplaceEvent.where(topic: "user.signed_up")

    {
      feed: serialize_feed(recent_events),
      counters: TOPICS.index_with { |topic| counters_by_topic[topic].to_i },
      orders_chart: serialize_orders_chart(orders),
      topic_distribution: TOPICS.map do |topic|
        { topic: topic, count: counters_by_topic[topic].to_i }
      end,
      recent_orders: serialize_recent_orders(orders.limit(10)),
      user_activity: {
        signups_last_24h: signup_events.where("created_at >= ?", 24.hours.ago).count,
        total_users: signup_events.count
      },
      updated_at: Time.current.iso8601
    }
  end

  def serialize_feed(events)
    now = Time.current

    events.map do |event|
      {
        id: event.id,
        topic: event.topic,
        timestamp: event.created_at.iso8601,
        payload_summary: payload_summary_for(event.topic, event.payload),
        status: (now - event.created_at) < 10 ? "pending" : "processed"
      }
    end
  end

  def serialize_orders_chart(orders)
    orders_scope = orders.reorder(created_at: :asc).to_a
    grouped = orders_scope.group_by { |event| event.created_at.beginning_of_minute }

    labels = grouped.keys.sort.map { |time| time.in_time_zone.strftime("%H:%M") }
    order_counts = grouped.keys.sort.map { |time| grouped[time].count }
    revenue_gbp = grouped.keys.sort.map do |time|
      grouped[time].sum { |event| amount_in_gbp(event.payload || {}) }.round(2)
    end

    {
      labels: labels,
      order_counts: order_counts,
      revenue_gbp: revenue_gbp,
      totals: {
        orders: orders.count,
        revenue_gbp: revenue_gbp.sum.round(2)
      }
    }
  end

  def serialize_recent_orders(order_events)
    order_events.map do |event|
      payload = event.payload || {}

      {
        order_id: payload["order_id"] || event.id,
        user_id: payload["user_id"] || "unknown",
        amount: amount_in_gbp(payload),
        currency: payload["currency"] || "GBP",
        status: payload["status"] || "processed",
        timestamp: event.created_at.iso8601
      }
    end
  end

  def amount_in_gbp(payload)
    amount_cents = payload["amount_cents"]
    amount = payload["amount"]

    return (amount_cents.to_f / 100.0).round(2) if amount_cents.present?
    return amount.to_f.round(2) if amount.present?

    0.0
  end

  def payload_summary_for(topic, payload)
    payload ||= {}

    case topic
    when "user.signed_up"
      "User ##{payload['user_id'] || 'unknown'} signed up"
    when "listing.viewed"
      "Listing ##{payload['listing_id'] || 'unknown'} viewed by user ##{payload['user_id'] || 'unknown'}"
    when "order.placed"
      "Order ##{payload['order_id'] || 'unknown'} placed for £#{format('%.2f', amount_in_gbp(payload))}"
    when "review.submitted"
      "Review ##{payload['review_id'] || 'unknown'} submitted (rating #{payload['rating'] || 'n/a'})"
    else
      payload.to_json
    end
  end
end
