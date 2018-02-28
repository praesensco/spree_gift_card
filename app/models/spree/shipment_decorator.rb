module Spree
  Shipment.class_eval do
    state_machine do
      after_transition to: :shipped, do: :deliver_e_gift_cards
    end

    def deliver_e_gift_cards
      e_gift_card_ids = line_items.
                        select(&:is_e_gift_card?).
                        map(&:gift_card).
                        map(&:id)
      return if e_gift_card_ids.none?
      Spree::GiftCard.deliverable.where(id: e_gift_card_ids).each do |gift_card|
        Spree::OrderMailer.gift_card_email(gift_card.id, order).deliver_later
      end
    end
  end
end
