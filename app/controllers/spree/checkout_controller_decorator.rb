Spree::CheckoutController.class_eval do
  before_action :load_gift_card, only: [:update], if: :payment_via_gift_card?
  before_action :add_gift_card_payments, only: [:update], if: :payment_via_gift_card?

  private

  def add_gift_card_payments
    if spree_current_user.present? && !spree_current_user.gift_cards.include?(@gift_card)
      spree_current_user.gift_cards << @gift_card
    end
    @order.add_gift_card_payments(@gift_card)

    # Remove other payment method parameters.
    params[:order].delete(:payments_attributes)
    params.delete(:payment_source)

    # Return to the Payments page if additional payment is needed.
    redirect_to checkout_state_path(@order.state) and return if @order.payments.valid.sum(:amount) < @order.total
  end

  def payment_via_gift_card?
    params[:state] == 'payment' &&
      params[:order].fetch(:payments_attributes, {}).present? &&
      params[:order][:payments_attributes].select { |payments_attribute| gift_card_payment_method.try(:id).to_s == payments_attribute[:payment_method_id] }.present?
  end

  def load_gift_card
    @gift_card = Spree::GiftCard.find_by(code: params[:payment_source][gift_card_payment_method.try(:id).to_s][:code])
    if @gift_card.nil?
      @gift_card = import_integrated_gift_card
    else
      sync_integrated_gift_card(@gift_card)
    end

    return if @gift_card
    redirect_to checkout_state_path(@order.state), flash: { error: Spree.t('gift_code_not_found') } and return
  end

  def gift_card_payment_method
    @gift_card_payment_method ||= Spree::PaymentMethod.gift_card.available.first
  end

  def import_integrated_gift_card; end

  def sync_integrated_gift_card(_gift_card)
    true
  end
end
