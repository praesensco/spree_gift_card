Spree::User.class_eval do
  has_many :user_gift_cards
  has_many :gift_cards, through: :user_gift_cards
end
