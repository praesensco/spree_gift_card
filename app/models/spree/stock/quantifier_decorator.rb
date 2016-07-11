module Spree
  module Stock
    Quantifier.class_eval do
      include Spree::QuantifierCanSupply
    end
  end
end
