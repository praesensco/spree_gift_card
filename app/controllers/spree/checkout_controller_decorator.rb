Spree::CheckoutController.class_eval do

  before_action :add_gift_card_payments, only: [:update]

  private

    def add_gift_card_payments
      gift_card_payment_method_id = Spree::PaymentMethod::GiftCard.available.first.try(:id).to_s
      if payment_via_gift_card?(gift_card_payment_method_id)
        gift_card = Spree::GiftCard.find_by(code: params[:payment_source][gift_card_payment_method_id][:code])
        unless gift_card
          flash[:error] = Spree.t('gift_code_not_found')
          redirect_to checkout_state_path(@order.state) and return
        end
        @order.add_gift_card_payments(gift_card)

        # Remove other payment method parameters.
        params[:order].delete(:payments_attributes)
        params.delete(:payment_source)

        # Return to the Payments page if additional payment is needed.
        if @order.payments.valid.sum(:amount) < @order.total
          redirect_to checkout_state_path(@order.state) and return
        end
      end
    end

    def payment_via_gift_card?(method_id)
      params[:state] == "payment" && params[:order][:payments_attributes].present? && params[:order][:payments_attributes].select { |payments_attribute| method_id == payments_attribute[:payment_method_id] }.present?
    end
end
