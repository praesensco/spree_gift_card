module Spree
  module Admin
    class GiftCardsController < Spree::Admin::ResourceController
      before_action :find_gift_card_variants, except: :destroy

      def new
        @is_e_gift_card = request.path.include?('new-digital')
        find_gift_card_variants
        render :new
      end

      def create
        @object.assign_attributes(gift_card_params)
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

      def find_gift_card_variants
        products = Product.not_deleted.gift_cards
        products = if @is_e_gift_card
                     products.e_gift_cards
                   else
                     products.not_e_gift_cards
                   end
        gift_card_product_ids = products.pluck(:id)
        @gift_card_variants = Variant.joins(:prices).where(["amount > 0 AND product_id IN (?)", gift_card_product_ids]).order("amount")
      end

      def gift_card_params
        params.require(:gift_card).permit(
          :email,
          :name,
          :note,
          :value,
          :variant_id,
          :sender_name,
          :sender_email,
          :delivery_on
        )
      end
    end
  end
end
