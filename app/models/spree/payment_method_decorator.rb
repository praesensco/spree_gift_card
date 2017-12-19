Spree::PaymentMethod.class_eval do
  scope :gift_card, -> { where(type: 'Spree::PaymentMethod::GiftCard') }

  def gift_card?
    self.class == Spree::PaymentMethod::GiftCard
  end
end
