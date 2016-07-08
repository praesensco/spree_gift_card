module Spree
  StoreCreditCategory.class_eval do
    scope :gift_card, -> { where(name: 'Gift Card') }
  end
end
