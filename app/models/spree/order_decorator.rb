module Spree
  module OrderDecorator
    def self.prepended(base)
      base.include Spree::Order::GiftCard
    end
  end
end

::Spree::Order.prepend(Spree::OrderDecorator)