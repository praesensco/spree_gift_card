class CreateSpreeUserGiftCards < ActiveRecord::Migration[4.2]
  def change
    create_table :spree_user_gift_cards do |t|
      t.integer :user_id
      t.integer :gift_card_id
      t.timestamps
    end
  end
end
