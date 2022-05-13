module Spree
  module AdjustmentDecorator
    def self.prepended(base)
      base.scope :gift_card, -> { where(source_type: 'Spree::GiftCard') }
    end
  end
end

::Spree::Adjustment.prepend(Spree::AdjustmentDecorator)