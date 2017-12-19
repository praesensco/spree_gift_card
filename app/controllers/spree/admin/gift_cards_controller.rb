module Spree
  module Admin
    class GiftCardsController < Spree::Admin::ResourceController
      before_action :set_gift_card, :find_gift_card_variant, except: :destroy

      def create
        @object.assign_attributes(gift_card_params)
        @object.variant_id = @gift_card_variant_id
        @object.current_value = @object.original_value
        if @object.save
          flash[:success] = Spree.t(:successfully_created_gift_card)
          redirect_to admin_gift_cards_path
        else
          render :new
        end
      end

      private

      def collection
        super.order(created_at: :desc).page(params[:page]).per(Spree::Config[:admin_orders_per_page])
      end

      def set_gift_card
        @is_e_gift_card = request.path.include?('new-digital') || (params[:gift_card] && params[:gift_card][:e_gift_card] == 'true')
      end

      def find_gift_card_variant
        products = Product.not_deleted.gift_cards
        products = if @is_e_gift_card
                     products.e_gift_cards
                   else
                     products.not_e_gift_cards
                   end
        @gift_card_variant_id = products.first.master.id
      end

      def gift_card_params
        params.require(:gift_card).permit(
          :email,
          :name,
          :note,
          :original_value,
          :sender_name,
          :sender_email,
          :delivery_on
        )
      end
    end
  end
end
