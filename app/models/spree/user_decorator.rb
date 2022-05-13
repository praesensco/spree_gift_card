module Spree
  module UserDecorator
    def self.prepended(base)
      base.has_many :user_gift_cards
      base.has_many :gift_cards, through: :user_gift_cards
    end
  end
end

::Spree::User.prepend(Spree::UserDecorator)