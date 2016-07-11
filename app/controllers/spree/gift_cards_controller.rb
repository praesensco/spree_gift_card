module Spree
  class GiftCardsController < Spree::StoreController

    before_action :load_master_variant, only: :new
    before_action :load_gift_card, only: :redeem

    def redeem
      if @gift_card.safely_redeem(spree_current_user)
        redirect_to redirect_after_redeem, flash: { success: 'Gift card has been redeemed successfully.' }
      else
        redirect_to root_path, flash: { error: @gift_card.errors.full_messages.to_sentence }
      end
    end

    def new
      find_gift_card_variants
      @gift_card = GiftCard.new
    end

    def create
      begin
        # Wrap the transaction script in a transaction so it is an atomic operation
        Spree::GiftCard.transaction do
          @gift_card = GiftCard.new(gift_card_params)
          @gift_card.save!
          # Create line item
          line_item = LineItem.new(quantity: 1)
          line_item.gift_card = @gift_card
          line_item.variant = @gift_card.variant
          line_item.price = @gift_card.variant.price
          # Add to order
          order = current_order(create_order_if_necessary: true)
          order.line_items << line_item
          line_item.order = order
          order.update_totals
          order.updater.update_item_count
          order.save!
          # Save gift card
          @gift_card.line_item = line_item
          @gift_card.save!
        end
        redirect_to cart_path
      rescue ActiveRecord::RecordInvalid
        find_gift_card_variants
        render :new
      end
    end

    private

    def redirect_after_redeem
      root_path
    end

    def load_gift_card
      @gift_card = Spree::GiftCard.where(code: params[:id]).last
    end

    def find_gift_card_variants
      gift_card_product_ids = Product.not_deleted.where(is_gift_card: true).pluck(:id)
      @gift_card_variants = Variant.joins(:prices).where(["amount > 0 AND product_id IN (?)", gift_card_product_ids]).order("amount")
    end

    def gift_card_params
      params.require(:gift_card).permit(:email, :name, :note, :variant_id)
    end

    def load_master_variant
      @master_variant = Spree::Product.find_by(slug: params[:product_id]).try(:master)
    end

  end
end
