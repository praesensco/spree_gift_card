Spree::LineItem.class_eval do

  has_one :gift_card, dependent: :destroy

  with_options if: -> { product.is_gift_card? } do
    validates :gift_card, presence: true
    validates :quantity,  numericality: { less_than_or_equal_to: 1 }
  end

end
