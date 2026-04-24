class MarketplaceEventsController < ApplicationController
  def index
    @events = MarketplaceEvent.order(created_at: :desc).limit(50)
  end
end
