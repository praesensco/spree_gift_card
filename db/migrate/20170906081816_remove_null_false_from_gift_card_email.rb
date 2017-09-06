class RemoveNullFalseFromGiftCardEmail < ActiveRecord::Migration
  def change
    change_column :spree_gift_cards, :email, :string, null: true
  end
end
