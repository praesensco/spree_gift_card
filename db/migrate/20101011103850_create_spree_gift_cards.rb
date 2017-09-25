class CreateSpreeGiftCards < ActiveRecord::Migration[4.2]
  def change
    create_table :spree_gift_cards do |t|
      t.integer :variant_id, :null => false
      t.integer :line_item_id
      t.string :email
      t.string :name
      t.string :sender_email
      t.string :sender_name
      t.text :note
      t.string :code, :null => false
      t.datetime :sent_at
      t.datetime :delivery_on
      t.decimal :current_value, :precision => 8, :scale => 2, :null => false
      t.decimal :original_value, :precision => 8, :scale => 2, :null => false
      t.timestamps
    end
  end
end
