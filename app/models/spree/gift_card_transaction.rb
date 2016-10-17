class Spree::GiftCardTransaction < ActiveRecord::Base
  belongs_to :gift_card
  belongs_to :order

  validates :amount, :gift_card, presence: true
end
