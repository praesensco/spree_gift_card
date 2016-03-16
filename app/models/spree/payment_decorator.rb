Spree::Payment.class_eval do

  state_machine.after_transition to: :completed, do: :send_gift_card

  def send_gift_card
    order.line_items.each do |li|
      Spree::OrderMailer.gift_card_email(li.gift_card.id, order).deliver if li.gift_card
    end
  end
end
