module Spree
  class Order
    module GiftCard
      extend ActiveSupport::Concern

      def add_gift_card_payments(gift_card)
        payments.gift_cards.checkout.map(&:invalidate!)

        if gift_card.present?
          payment_method = Spree::PaymentMethod::GiftCard.available.first
          raise "Gift Card payment method could not be found" unless payment_method

          amount_to_take = gift_card_amount(gift_card, outstanding_balance_after_applied_store_credit)
          create_gift_card_payment(payment_method, gift_card, amount_to_take)
        end
      end

      def total_applied_gift_card
        payments.gift_cards.valid.sum(:amount)
      end

      def using_gift_card?
        total_applied_gift_card > 0
      end

      def display_total_applied_gift_card
        Spree::Money.new(-total_applied_gift_card, currency: currency)
      end

      included do
        def order_total_after_store_credit_with_gift_card
          order_total_after_store_credit_without_gift_card - total_applied_gift_card
        end
        alias_method_chain :order_total_after_store_credit, :gift_card
      end

      def add_store_credit_payments
        payments.store_credits.where(state: 'checkout').map(&:invalidate!)

        remaining_total = outstanding_balance - total_applied_gift_card

        if user && user.store_credits.any?
          payment_method = Spree::PaymentMethod::StoreCredit.available.first
          raise "Store credit payment method could not be found" unless payment_method

          user.store_credits.order_by_priority.each do |credit|
            break if remaining_total.zero?
            next if credit.amount_remaining.zero?

            amount_to_take = store_credit_amount(credit, remaining_total)
            create_store_credit_payment(payment_method, credit, amount_to_take)
            remaining_total -= amount_to_take
          end
        end
      end

      private

        def create_gift_card_payment(payment_method, gift_card, amount)
          payments.create!(
            source: gift_card,
            payment_method: payment_method,
            amount: amount,
            state: 'checkout',
            response_code: gift_card.generate_authorization_code
          )
        end

        def gift_card_amount(gift_card, total)
          [gift_card.amount_remaining, total].min
        end

        def outstanding_balance_after_applied_store_credit
          outstanding_balance - total_applied_store_credit
        end
    end
  end
end
