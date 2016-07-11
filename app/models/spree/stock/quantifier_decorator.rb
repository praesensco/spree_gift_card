module Spree
  module Stock
    Quantifier.class_eval do

      def can_supply?(required=1)
        super || Spree::Variant.find(@variant).product.is_gift_card?
      end
    end
  end
end
