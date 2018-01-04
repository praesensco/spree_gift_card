module Spree
  # GiftCard class enhancement
  class GiftCard < ActiveRecord::Base
    has_many :user_gift_cards
    has_many :users, through: :user_gift_cards

    # GiftCard may have many owners
    module Users
      def belongs_to?(user)
        owners.include?(user)
      end
    end
  end
end
