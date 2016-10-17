FactoryGirl.define do
  factory :gift_card, class: Spree::GiftCard do
    email 'spree@example.com'
    name 'Example User'
    variant
    line_item
  end

  factory :gift_card_payment_method, class: Spree::PaymentMethod::GiftCard do
    type "Spree::PaymentMethod::GiftCard"
    name "Gift Card"
    description "Gift Card"
    active true
    auto_capture false
  end

  factory :gift_card_payment, class: Spree::Payment, parent: :payment do
    association(:payment_method, factory: :gift_card_payment_method)
    association(:source, factory: :gift_card)
  end

  factory :gift_card_store_credit_category, class: Spree::StoreCreditCategory, parent: :store_credit_category do
    name "Gift Card"
  end

  factory :gift_card_transaction, class: Spree::GiftCardTransaction do
    gift_card
    action             { Spree::GiftCard::AUTHORIZE_ACTION }
    amount             { 100.00 }
    authorization_code { "#{gift_card.id}-SC-20140602164814476128" }
  end
end
