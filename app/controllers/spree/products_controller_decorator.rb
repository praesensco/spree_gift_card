module Spree
  module ProductsControllerDecorator

    def self.prepended(base)
      base.before_action :redirect_gift_card, only: :show
    end

    private

    def redirect_gift_card
      redirect_to new_gift_card_path(product_id: @product) && return if @product.try :is_gift_card?
    end
  end
end

::Spree::ProductsController.prepend(Spree::ProductsControllerDecorator)