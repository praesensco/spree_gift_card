module Spree
  module LineItemDecorator
    
    def self.prepended(base)
      base.has_one :gift_card, dependent: :destroy

      with_options if: :is_gift_card? do
        base.validates :gift_card, presence: true
        base.validates :quantity,  numericality: { less_than_or_equal_to: MAXIMUM_GIFT_CARD_LIMIT }, allow_nil: true
      end

      base.delegate :is_gift_card?, to: :product
      base.delegate :is_e_gift_card?, to: :product
    end

    MAXIMUM_GIFT_CARD_LIMIT ||= 1

    # with_options if: :is_gift_card? do
    #   validates :gift_card, presence: true
    #   validates :quantity,  numericality: { less_than_or_equal_to: MAXIMUM_GIFT_CARD_LIMIT }, allow_nil: true
    # end

    # delegate :is_gift_card?, to: :product
    # delegate :is_e_gift_card?, to: :product
  end
end

::Spree::LineItem.prepend(Spree::LineItemDecorator)