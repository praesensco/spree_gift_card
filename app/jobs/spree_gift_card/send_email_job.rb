module SpreeGiftCard
  class SendEmailJob < ApplicationJob
    queue_as :default

    def perform(*_args)
      e_gift_card_product = Spree::Product.find_by_slug('e-gift-card')
      return unless e_gift_card_product

      Spree::GiftCard.
        deliverable.
        where(variant: e_gift_card_product.master).
        where.not(line_item: nil).
        each do |gift_card|
          next unless gift_card_shipped(gift_card)
          order = gift_card.line_item.order
          Spree::OrderMailer.gift_card_email(gift_card.id, order).deliver_later
        end
    end

    def gift_card_shipped(gift_card)
      gift_card.line_item.inventory_units.all?(&:shipped?)
    end
  end
end
