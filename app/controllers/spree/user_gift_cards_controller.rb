module Spree
  class UserGiftCardsController < Spree::StoreController
    load_and_authorize_resource class: Spree::GiftCard

    def create
      code = params[:code]
      redirect_to action: :new if code.blank?

      # Check if GC is defined in Spree
      spree_gift_card = Spree::GiftCard.find_by_code(code)
      if spree_gift_card.present?
        spree_current_user.gift_cards << spree_gift_card
        flash[:success] = 'Gift Card added'
        # If GC is not defined in Spree, check if it is defined in integrated services
      elsif !import_integrated_gift_card
        # If no GC found, return error
        flash[:error] = 'Invalid Gift Card code. Please try again.'
      end

      redirect_to action: :index
    end

    def index
      # Update balance for all the Gift Cards
      spree_current_user.springboard_import_gift_cards_balance
      @gift_cards = spree_current_user.gift_cards
    end

    def new; end

    private

    def import_integrated_gift_card; end
  end
end
