module Spree
  module StoreCreditCategoryDecorator
    def self.prepended(base)
      base.scope :gift_card, -> { where(name: 'Gift Card') }
    end
  end
end

::Spree::StoreCreditCategory.prepend(Spree::StoreCreditCategoryDecorator)