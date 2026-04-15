class OrdersController < ApplicationController
  def index
    @orders = Order.all
  end

  def new
    @order = Order.new
  end

  def create
    @order = Order.new(order_params)
    @order.status = "pending"

    if @order.save
      OrderProducer.call(@order)
      redirect_to orders_path, notice: "Order placed!"
    else
      render :new
    end
  end

  private

  def order_params
    params.require(:order).permit(:description)
  end
end