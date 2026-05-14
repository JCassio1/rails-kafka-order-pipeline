import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

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
    this.ordersChart = null
    this.distributionChart = null
    this.poll()
    this.timer = setInterval(() => this.poll(), this.intervalValue)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
    if (this.ordersChart) this.ordersChart.destroy()
    if (this.distributionChart) this.distributionChart.destroy()
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
    const ctx = this.ordersChartTarget.getContext("2d")
    const dataset = {
      labels: series.labels || [],
      datasets: [
        {
          label: "Orders",
          data: series.order_counts || [],
          borderColor: "#b73e2f",
          backgroundColor: "rgba(183, 62, 47, 0.2)",
          tension: 0.3,
          fill: true
        }
      ]
    }

    if (this.ordersChart) {
      this.ordersChart.data = dataset
      this.ordersChart.update()
      return
    }

    this.ordersChart = new Chart(ctx, {
      type: "line",
      data: dataset,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } }
      }
    })
  }

  renderDistributionChart(rows) {
    const ctx = this.distributionChartTarget.getContext("2d")
    const data = {
      labels: rows.map((row) => row.topic),
      datasets: [
        {
          data: rows.map((row) => row.count),
          backgroundColor: ["#b73e2f", "#d46a53", "#e28f6a", "#9d3c2d"],
          borderWidth: 0
        }
      ]
    }

    if (this.distributionChart) {
      this.distributionChart.data = data
      this.distributionChart.update()
      return
    }

    this.distributionChart = new Chart(ctx, {
      type: "doughnut",
      data: data,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: "bottom" }
        }
      }
    })
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
