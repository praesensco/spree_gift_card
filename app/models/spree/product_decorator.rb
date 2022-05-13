module Spree
  module ProductDecorator
    def self.prepended(base)
      base.scope :gift_cards, -> { where(is_gift_card: true) }
      base.scope :not_gift_cards, -> { where(is_gift_card: false) }
      base.scope :e_gift_cards, -> { where(is_e_gift_card: true) }
      base.scope :not_e_gift_cards, -> { where(is_e_gift_card: false) }
    end
  end
end

::Spree::Product.prepend(Spree::ProductDecorator)