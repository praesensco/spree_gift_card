module Spree
  class UserGiftCard < ActiveRecord::Base
    belongs_to :gift_card
    belongs_to :user
  end
end
