Spree::Payment.class_eval do
  scope :gift_cards, -> { where(source_type: Spree::GiftCard.to_s) }

  delegate :gift_card?, to: :payment_method, allow_nil: true

  def store_credit_or_gift_card?
    store_credit? || gift_card?
  end

  private

  def invalidate_old_payments
    return if store_credit_or_gift_card?
    order.payments.with_state('checkout').where("id != ?", id).each do |payment|
      payment.invalidate! unless payment.store_credit_or_gift_card?
    end
  end
end
