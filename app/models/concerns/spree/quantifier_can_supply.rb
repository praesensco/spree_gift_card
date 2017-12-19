module Spree
  module QuantifierCanSupply
    def can_supply?(required = 1)
      product = Spree::Variant.find(@variant).product
      if product.is_e_gift_card?
        true
      else
        super || product.is_gift_card?
      end
    end
  end
end
