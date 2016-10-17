class AddActionAndAuthorizationCodeToSpreeGiftCardTransaction < ActiveRecord::Migration
  def change
    add_column :spree_gift_card_transactions, :action, :string
    add_column :spree_gift_card_transactions, :authorization_code, :string
  end
end
