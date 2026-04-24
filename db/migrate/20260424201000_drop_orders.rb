class DropOrders < ActiveRecord::Migration[8.1]
  def change
    drop_table :orders, if_exists: true
  end
end
