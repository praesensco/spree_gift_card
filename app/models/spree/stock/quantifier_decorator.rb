module Spree
  module Stock
    Quantifier.class_eval do

      alias_method :original_can_supply?, :can_supply?

      def can_supply?(required=1)
        original_can_supply?(required) || Spree::Variant.find(@variant).product.is_gift_card?
      end
    end
  end
end
