import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "feed",
    "counters",
    "ordersChart",
    "distributionChart",
    "recentOrders",
    "signups24h",
    "totalUsers",
    "ordersTotal",
    "revenueTotal",
    "updatedAt"
  ]

  static values = {
    url: String,
    interval: { type: Number, default: 3000 }
  }

  connect() {
    this.poll()
    this.timer = setInterval(() => this.poll(), this.intervalValue)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  async poll() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) return
      const data = await response.json()
      this.render(data)
    } catch (_error) {
      // Keep UI resilient during intermittent fetch failures.
    }
  }

  render(data) {
    this.renderCounters(data.counters || {})
    this.renderFeed(data.feed || [])
    this.renderOrdersChart(data.orders_chart || {})
    this.renderDistributionChart(data.topic_distribution || [])
    this.renderRecentOrders(data.recent_orders || [])
    this.signups24hTarget.textContent = data.user_activity?.signups_last_24h || 0
    this.totalUsersTarget.textContent = data.user_activity?.total_users || 0
    this.ordersTotalTarget.textContent = data.orders_chart?.totals?.orders || 0
    this.revenueTotalTarget.textContent = this.formatGBP(data.orders_chart?.totals?.revenue_gbp || 0)
    this.updatedAtTarget.textContent = this.formatTimestamp(data.updated_at)
  }

  renderCounters(counters) {
    this.countersTarget.querySelectorAll("[data-topic]").forEach((el) => {
      const topic = el.dataset.topic
      el.textContent = counters[topic] || 0
    })
  }

  renderFeed(feed) {
    if (feed.length === 0) {
      this.feedTarget.innerHTML = "<p class='empty-state'>No marketplace events yet.</p>"
      return
    }

    this.feedTarget.innerHTML = feed
      .map((event) => {
        const statusClass = event.status === "pending" ? "status-pending" : "status-processed"
        return `
          <li class="feed-item">
            <div class="feed-item-top">
              <span class="feed-topic">${event.topic}</span>
              <span class="status-pill ${statusClass}">${event.status}</span>
            </div>
            <p class="feed-summary">${event.payload_summary}</p>
            <p class="feed-time">${this.formatTimestamp(event.timestamp)}</p>
          </li>
        `
      })
      .join("")
  }

  renderOrdersChart(series) {
    const labels = series.labels || []
    const values = (series.order_counts || []).map((v) => Number(v || 0))

    if (values.length === 0 || values.every((n) => Number(n) === 0)) {
      this.ordersChartTarget.innerHTML = "<div class='chart-empty'>No order volume yet</div>"
      return
    }

    const max = Math.max(...values, 1)
    const min = Math.min(...values)
    const range = Math.max(max - min, 1)
    const bars = values
      .map((value, idx) => {
        // Stretch small deltas so adjacent counts remain visible.
        const normalized = ((value - min) / range) * 0.84 + 0.12
        const height = Math.max(8, Math.round(normalized * 100))
        const label = labels[idx] || `T${idx + 1}`
        return `
          <div class="bar-col" title="${label}: ${value} orders">
            <div class="bar-track">
              <div class="bar" style="height:${height}%"></div>
            </div>
            <span class="bar-value">${value}</span>
            <span class="bar-label">${label}</span>
          </div>
        `
      })
      .join("")

    this.ordersChartTarget.innerHTML = `
      <div class="orders-chart">
        <div class="orders-bars">${bars}</div>
      </div>
    `
  }

  renderDistributionChart(rows) {
    const total = rows.reduce((sum, row) => sum + Number(row.count || 0), 0)

    if (total <= 0) {
      this.distributionChartTarget.innerHTML = "<div class='chart-empty'>No topic events yet</div>"
      return
    }

    let current = 0
    const colors = ["#b73e2f", "#d46a53", "#e28f6a", "#9d3c2d"]

    const slices = rows.map((row, idx) => {
      const value = Number(row.count || 0)
      const portion = (value / total) * 100
      const start = current
      const end = current + portion
      current = end
      return {
        topic: row.topic,
        count: value,
        start,
        end,
        color: colors[idx % colors.length]
      }
    })

    const gradient = slices.map((s) => `${s.color} ${s.start}% ${s.end}%`).join(", ")
    const legend = slices
      .map((s) => {
        return `
          <li class="dist-legend-item">
            <span class="dist-dot" style="background:${s.color}"></span>
            <span class="dist-topic">${s.topic}</span>
            <span class="dist-count">${s.count}</span>
          </li>
        `
      })
      .join("")

    this.distributionChartTarget.innerHTML = `
      <div class="dist-wrap">
        <div class="dist-donut" style="background: conic-gradient(${gradient})">
          <div class="dist-hole">${total}</div>
        </div>
        <ul class="dist-legend">${legend}</ul>
      </div>
    `
  }

  renderRecentOrders(orders) {
    if (orders.length === 0) {
      this.recentOrdersTarget.innerHTML = "<tr><td colspan='6' class='orders-empty'>No recent orders</td></tr>"
      return
    }

    this.recentOrdersTarget.innerHTML = orders
      .map((order) => {
        return `
          <tr>
            <td>${order.order_id}</td>
            <td>${order.user_id}</td>
            <td>${this.formatGBP(order.amount)}</td>
            <td>${order.currency || "GBP"}</td>
            <td>${order.status || "processed"}</td>
            <td>${this.formatTimestamp(order.timestamp)}</td>
          </tr>
        `
      })
      .join("")
  }

  formatGBP(amount) {
    return new Intl.NumberFormat("en-GB", {
      style: "currency",
      currency: "GBP"
    }).format(Number(amount || 0))
  }

  formatTimestamp(value) {
    if (!value) return "-"
    return new Date(value).toLocaleString("en-GB")
  }
}
