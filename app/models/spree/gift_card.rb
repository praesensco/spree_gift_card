require 'spree/core/validators/email'

module Spree
  class GiftCard < ActiveRecord::Base
    include CalculatedAdjustments
    include Spree::GiftCard::Users

    UNACTIVATABLE_ORDER_STATES = %w[complete awaiting_return returned].freeze
    AUTHORIZE_ACTION = 'authorize'.freeze
    CAPTURE_ACTION = 'capture'.freeze
    VOID_ACTION = 'void'.freeze
    CREDIT_ACTION = 'credit'.freeze
    VALUES = [50, 100, 150, 200, 250, 300, 500, 1000].freeze

    belongs_to :variant
    belongs_to :line_item

    has_many :transactions, class_name: 'Spree::GiftCardTransaction'

    validates :current_value, :original_value, :code, presence: true

    with_options allow_blank: true do
      validates :code, uniqueness: { case_sensitive: false }
      validates :current_value, numericality: { greater_than_or_equal_to: 0 }
      validates :email, email: true
    end

    validates :email, :name, :sender_name, :sender_email, :note, presence: true, if: :e_gift_card?
    validates :sender_email, email: true, if: :e_gift_card?

    validate :amount_remaining_is_positive, if: :current_value

    before_validation :generate_code, on: :create
    before_validation :set_values, on: :create

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }

    def e_gift_card?
      variant.product.is_e_gift_card?
    end

    def safely_redeem(user)
      if able_to_redeem?(user)
        redeem(user)
      elsif amount_remaining.to_f > 0.0
        errors[:base] = Spree.t('errors.gift_card.unauthorized')
        false
      else
        errors[:base] = Spree.t('errors.gift_card.already_redeemed')
        false
      end
    end

    def amount_remaining
      current_value - authorized_amount
    end

    def authorize(amount, options = {})
      authorization_code = options[:action_authorization_code]
      if authorization_code
        return true if transactions.find_by(action: AUTHORIZE_ACTION, authorization_code: authorization_code)
        errors.add(:base, Spree.t('gift_card_payment_method.unable_to_capture', auth_code: authorization_code))
        return false
      else
        authorization_code = generate_authorization_code
      end

      if valid_authorization?(amount)
        transaction = transactions.build(action: AUTHORIZE_ACTION, amount: amount, authorization_code: authorization_code)
        transaction.order = Spree::Order.find_by(number: options[:order_number]) if options[:order_number]
        self.authorized_amount = authorized_amount + amount
        save!
        authorization_code
      else
        false
      end
    end

    def valid_authorization?(amount)
      if amount_remaining.to_d < amount.to_d
        errors.add(:base, Spree.t('gift_card_payment_method.insufficient_funds'))
        false
      else
        true
      end
    end

    def capture(amount, authorization_code, options = {})
      return false unless authorize(amount, action_authorization_code: authorization_code)
      if amount <= authorized_amount
        transaction = transactions.build(action: CAPTURE_ACTION, amount: amount, authorization_code: authorization_code)
        transaction.order = Spree::Order.find_by(number: options[:order_number]) if options[:order_number]
        self.authorized_amount = authorized_amount - amount
        self.current_value = current_value - amount
        save!
        authorization_code
      else
        errors.add(:base, Spree.t('gift_card_payment_method.insufficient_authorized_amount'))
        false
      end
    end

    def void(authorization_code, options = {})
      auth_transaction = transactions.find_by(action: AUTHORIZE_ACTION, authorization_code: authorization_code)
      if auth_transaction
        amount = auth_transaction.amount
        transaction = transactions.build(action: VOID_ACTION, amount: amount, authorization_code: authorization_code)
        transaction.order = Spree::Order.find_by(number: options[:order_number]) if options[:order_number]
        self.authorized_amount = authorized_amount - amount
        save!
        true
      else
        errors.add(:base, Spree.t('gift_card_payment_method.unable_to_void', auth_code: authorization_code))
        false
      end
    end

    def credit(amount, authorization_code, options = {})
      capture_transaction = transactions.find_by(action: CAPTURE_ACTION, authorization_code: authorization_code)
      if capture_transaction && amount <= capture_transaction.amount
        transaction = transactions.build(action: CREDIT_ACTION, amount: amount, authorization_code: authorization_code)
        transaction.order = Spree::Order.find_by(number: options[:order_number]) if options[:order_number]
        self.current_value = current_value + amount
        save!
        true
      else
        errors.add(:base, Spree.t('gift_card_payment_method.unable_to_credit', auth_code: authorization_code))
        false
      end
    end

    # Calculate the amount to be used when creating an adjustment
    def compute_amount(calculable)
      calculator.compute(calculable, self)
    end

    def debit(amount, order = nil)
      raise 'Cannot debit gift card by amount greater than current value.' if (amount_remaining - amount.to_f.abs) < 0
      transaction = transactions.build
      transaction.amount = amount
      transaction.order  = order if order
      self.current_value = current_value - amount.abs
      save
    end

    def price
      line_item ? line_item.price * line_item.quantity : variant.price
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

    def actions
      %i[capture void]
    end

    def generate_authorization_code
      "#{id}-GC-#{Time.now.utc.strftime('%Y%m%d%H%M%S%6N')}"
    end

    def can_void?(payment)
      payment.pending?
    end

    def can_capture?(payment)
      %w[checkout pending].include?(payment.state)
    end

    private

    def redeem(user)
      transaction do
        previous_current_value = amount_remaining
        debit(amount_remaining)
        build_store_credit(user, previous_current_value).save!
      end
    rescue Exception => e
      errors[:base] = 'There some issue while redeeming the gift card.'
      false
    end

    def build_store_credit(user, previous_current_value)
      user.store_credits.build(
        amount: previous_current_value,
        category: Spree::StoreCreditCategory.gift_card.last,
        memo: "Gift Card - #{line_item.product.name} received from #{recieved_from}",
        created_by: user,
        action_originator: user,
        currency: Spree::Config[:currency]
      )
    end

    def recieved_from
      line_item.order.email
    end

    def generate_code
      until code.present? && self.class.where(code: code).count.zero?
        chars = [('a'..'z'), ('0'..'9')].map(&:to_a).flatten
        self.code = Array.new(16) { chars[rand(chars.count)] }.join
      end
    end

    def set_values
      self.current_value ||= line_item.try(:price)
      self.original_value ||= line_item.try(:price)
    end

    def amount_remaining_is_positive
      unless amount_remaining >= 0.0
        errors.add(:authorized_amount, Spree.t('errors.gift_card.greater_than_current_value'))
      end
    end

    def able_to_redeem?(user)
      Spree::Config.allow_gift_card_redeem &&
        user &&
        user.email == email &&
        amount_remaining.to_f > 0.0 && line_item.order.completed?
    end
  end
end
