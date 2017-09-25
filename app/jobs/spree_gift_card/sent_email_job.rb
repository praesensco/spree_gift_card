module SpreeGiftCard
  class SentEmailJob < ApplicationJob
    queue_as :default

    def perform(*_args)
      gift_cards = Spree::GiftCard.active.has_springboard_id.where.not(delivery_on: nil)
      gift_cards.each do |gift_card|
        if gift_card.line_item.is_e_gift_card?
          Spree::OrderMailer.gift_card_email(gift_card.id, gift_card.line_item.order).deliver
        end
      end
    end
  end
end
