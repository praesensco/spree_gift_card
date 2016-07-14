require 'spree/core/validators/email'

module Spree
  class GiftCard < ActiveRecord::Base
    include CalculatedAdjustments

    UNACTIVATABLE_ORDER_STATES = ["complete", "awaiting_return", "returned"]

    belongs_to :variant
    belongs_to :line_item

    has_many :transactions, class_name: 'Spree::GiftCardTransaction'

    validates :code, uniqueness: true, allow_blank: true
    validates :current_value, :name, :original_value, :code, presence: true
    validates :email, email: true, presence: true

    before_validation :generate_code, on: :create
    before_validation :set_values, on: :create

    def safely_redeem(user)
      if user && user.email == email && current_value.to_f > 0.0 && line_item.order.completed?
        redeem(user)
      elsif current_value.to_f > 0.0
        self.errors[:base] = 'You are not authorized to perform this action.'
        false
      else
        self.errors[:base] = 'This Card has already been redeemed.'
        false
      end
    end

    def apply(order)
      # Nothing to do if the gift card is already associated with the order
      return false if order.gift_credit_exists?(self)
      order.update!
      Spree::Adjustment.create!(
            amount: compute_amount(order),
            order: order,
            adjustable: order,
            source: self,
            mandatory: true,
            label: Spree.t(:gift_card_discount)
          )

      order.update!
    end

    # Calculate the amount to be used when creating an adjustment
    def compute_amount(calculable)
      self.calculator.compute(calculable, self)
    end

    def debit(amount, order = nil)
      raise 'Cannot debit gift card by amount greater than current value.' if (self.current_value - amount.to_f.abs) < 0
      transaction = self.transactions.build
      transaction.amount = amount
      transaction.order  = order if order
      self.current_value = self.current_value - amount.abs
      self.save
    end

    def price
      self.line_item ? self.line_item.price * self.line_item.quantity : self.variant.price
    end

    def order_activatable?(order)
      order &&
      created_at < order.created_at &&
      current_value > 0 &&
      !UNACTIVATABLE_ORDER_STATES.include?(order.state)
    end

    def calculator
      @calculator ||= Spree::Calculator::GiftCardCalculator.new
    end

    private

    def redeem(user)
      begin
        transaction do
          previous_current_value = current_value
          debit(current_value)
          build_store_credit(user, previous_current_value).save!
        end
      rescue
        self.errors[:base] = 'There some issue while redeeming the gift card.'
        false
      end
    end

    def build_store_credit(user, previous_current_value)
      user.store_credits.build(
            amount: previous_current_value,
            category: Spree::StoreCreditCategory.gift_card.last,
            memo: "Gift Card - #{ variant.sku } received from #{ recieved_from }",
            created_by: user,
            action_originator: user,
            currency: Spree::Config[:currency]
        )
    end

    def recieved_from
      line_item.order.email
    end

    def generate_code
      until self.code.present? && self.class.where(code: self.code).count == 0
        self.code = Digest::SHA1.hexdigest([Time.now, rand].join)
      end
    end

    def set_values
      self.current_value  = self.variant.try(:price)
      self.original_value = self.variant.try(:price)
    end

  end
end
