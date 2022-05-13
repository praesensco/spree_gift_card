module Spree
  class UserGiftCardsController < Spree::StoreController
    before_action :authorize

    def create
      debugger

      code = params[:code]
      if code.blank?
        flash[:error] = 'Invalid Gift Card code.'
        redirect_to action: :new
      end

      # Check if GC is defined in Spree
      gift_card = Spree::GiftCard.find_by_code(code)
      if gift_card.present?
        spree_current_user.gift_cards << gift_card
        flash[:success] = 'Gift Card added'
        # If GC is not defined in Spree, check if it is defined in integrated services
      elsif !import_integrated_gift_card
        # If no GC found, return error
        flash[:error] = 'Invalid Gift Card code. Please try again.'
      end

      redirect_to action: :index
    end

    def index
      @gift_cards = spree_current_user.gift_cards
    end

    def new
      debugger
    end

    private

    def authorize
      redirect_to root_path unless spree_current_user.present?
    end

    def import_integrated_gift_card; end
  end
end
