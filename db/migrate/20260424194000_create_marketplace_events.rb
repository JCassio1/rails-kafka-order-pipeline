class CreateMarketplaceEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :marketplace_events do |t|
      t.string :topic, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :marketplace_events, :topic
    add_index :marketplace_events, :event_type
    add_index :marketplace_events, :created_at
  end
end
