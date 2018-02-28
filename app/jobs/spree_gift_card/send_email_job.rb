module SpreeGiftCard
  class SendEmailJob < ApplicationJob
    queue_as :default

    def perform(*_args)
      gift_cards = Spree::GiftCard.
                   active.
                   joins(:line_item).
                   where(sent_at: nil).
                   where.not(delivery_on: nil).
                   select { |gc| gc.delivery_on.to_date <= Time.now.to_date && gc.line_item.is_e_gift_card? }
      gift_cards.each do |gift_card|
        Spree::OrderMailer.gift_card_email(gift_card.id, gift_card.line_item.order).deliver
      end
    end
  end
end
