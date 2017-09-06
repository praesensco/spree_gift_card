class AddSenderInformationToGiftCard < ActiveRecord::Migration
  def change
    add_column :spree_gift_cards, :sender_email, :string
    add_column :spree_gift_cards, :sender_name, :string
    add_column :spree_gift_cards, :delivery_on, :datetime
  end
end
