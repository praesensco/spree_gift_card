require 'spec_helper'

describe Spree::GiftCard, type: :model do

  # Associations
  it { is_expected.to have_many(:transactions) }

  # Constants
  it { expect(Spree::GiftCard::UNACTIVATABLE_ORDER_STATES).to eq(["complete", "awaiting_return", "returned"]) }
  it { expect(Spree::GiftCard::AUTHORIZE_ACTION).to eq('authorize') }
  it { expect(Spree::GiftCard::CAPTURE_ACTION).to eq('capture') }
  it { expect(Spree::GiftCard::VOID_ACTION).to eq('void') }
  it { expect(Spree::GiftCard::CREDIT_ACTION).to eq('credit') }

  # Validations
  it { is_expected.to validate_presence_of(:current_value) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:original_value) }
  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to validate_numericality_of(:current_value).is_greater_than_or_equal_to(0).allow_nil }

  describe "amount_remaining_is_positive" do
    let(:variant) { create(:variant, price: 25) }
    let(:gift_card) { create(:gift_card, variant: variant) }

    context "when current_value is greater than authorized_amount" do
      before do
        gift_card.current_value = 25.0
        gift_card.authorized_amount = 20.0
      end

      it "expects not to add error to authorized_amount" do
        gift_card.valid?
        expect(gift_card.errors[:authorized_amount]).not_to include(Spree.t('errors.gift_card.greater_than_current_value'))
      end
    end

    context "when current_value is equal to authorized_amount" do
      before do
        gift_card.current_value = 25.0
        gift_card.authorized_amount = 25.0
      end

      it "expects not to add error to authorized_amount" do
        gift_card.valid?
        expect(gift_card.errors[:authorized_amount]).not_to include(Spree.t('errors.gift_card.greater_than_current_value'))
      end
    end

    context "when current_value is less than authorized_amount" do
      before do
        gift_card.current_value = 25.0
        gift_card.authorized_amount = 30.0
      end

      it "expects to add error to authorized_amount" do
        gift_card.valid?
        expect(gift_card.errors[:authorized_amount]).to include(Spree.t('errors.gift_card.greater_than_current_value'))
      end
    end
  end

  it "expects to generate code before create" do
    card = Spree::GiftCard.create(:email => "test@mail.com", :name => "John", :variant_id => create(:variant).id)
    expect(card.code).not_to be_nil
  end

  it "expects to set current_value and original_value before create" do
    card = Spree::GiftCard.create(:email => "test@mail.com", :name => "John", :variant_id => create(:variant).id)
    expect(card.current_value).not_to be_nil
    expect(card.original_value).not_to be_nil
  end

  context '#activatable?' do
    let(:gift_card) { create(:gift_card, variant: create(:variant, price: 25)) }

    it 'expects to be activatable if created before order, has current value, and order state valid' do
      expect(gift_card.order_activatable?(mock_model(Spree::Order, state: 'cart', created_at: (gift_card.created_at + 1.second)))).to be_truthy
    end

    it 'expects not to be activatable if created after order' do
      expect(gift_card.order_activatable?(mock_model(Spree::Order, state: 'cart', created_at: (gift_card.created_at - 1.second)))).to be_falsey
    end

    it 'expects not to be activatable if no current value' do
      allow(gift_card).to receive(:current_value).and_return(0)
      expect(gift_card.order_activatable?(mock_model(Spree::Order, state: 'cart', created_at: (gift_card.created_at + 1.second)))).to be_falsey
    end

    it 'expects not to be activatable if invalid order state' do
      expect(gift_card.order_activatable?(mock_model(Spree::Order, state: 'complete', created_at: (gift_card.created_at + 1.second)))).to be_falsey
    end
  end

  describe "#amount_remaining" do
    let(:variant) { create(:variant, price: 25) }
    let(:gift_card) { create(:gift_card, variant: variant) }

    before do
      gift_card.current_value = 25.2
      gift_card.authorized_amount = 20.3
    end

    it "expects to return difference of current_value and authorized_amount" do
      expect(gift_card.amount_remaining).to eq(4.9)
    end
  end

  describe "authorize" do
    let(:variant) { create(:variant, price: 25) }
    let(:gift_card) { create(:gift_card, variant: variant) }
    let(:order) { create(:order) }

    def gift_card_authorize
      gift_card.authorize(authorized_amount, order_number: order.number)
    end

    context "when already authorized" do
      let(:auth_code) { gift_card.generate_authorization_code }
      let(:authorized_amount)  { 13.0 }

      before do
        gift_card.transactions.create!(action: Spree::GiftCard::AUTHORIZE_ACTION, amount: authorized_amount, authorization_code: auth_code)
      end

      it "expects to return true" do
        expect(gift_card.authorize(authorized_amount, action_authorization_code: auth_code)).to be_truthy
      end

      it "expects not to re-authorize given amount" do
        expect {
          gift_card.authorize(authorized_amount, action_authorization_code: auth_code)
        }.to_not change { gift_card.authorized_amount }
      end
    end

    context "when authorization amount is less than amount remaining" do
      let(:authorized_amount)  { 23.9 }

      it "expects not to return false" do
        expect(gift_card_authorize).to_not be_falsey
      end

      it "expects to authorize given amount" do
        expect {
          gift_card_authorize
        }.to change { gift_card.authorized_amount }.by(authorized_amount)
      end

      it "expects to create an authorize transaction for the given amount" do
        gift_card_authorize
        expect(gift_card.transactions.where(action: Spree::GiftCard::AUTHORIZE_ACTION, amount: authorized_amount, order: order).exists?).to be_truthy
      end
    end

    context "when authorization amount is equal to amount remaining" do
      let(:authorized_amount)  { 25.0 }

      it "expects not to return false" do
        expect(gift_card_authorize).to_not be_falsey
      end

      it "expects to authorize given amount" do
        expect {
          gift_card_authorize
        }.to change { gift_card.authorized_amount }.by(authorized_amount)
      end

      it "expects to create an authorize transaction for the given amount" do
        gift_card_authorize
        expect(gift_card.transactions.where(action: Spree::GiftCard::AUTHORIZE_ACTION, amount: authorized_amount, order: order).exists?).to be_truthy
      end
    end

    context "when authorization amount is greater than amount remaining" do
      let(:authorized_amount)  { 26.0 }

      it "expects to return false" do
        expect(gift_card_authorize).to be_falsey
      end

      it "expects not to authorize given amount" do
        expect {
          gift_card_authorize
        }.not_to change { gift_card.authorized_amount }
      end

      it "expects not to create an authorize transaction for the given amount" do
        gift_card_authorize
        expect(gift_card.transactions.where(action: Spree::GiftCard::AUTHORIZE_ACTION, amount: authorized_amount, order: order).exists?).to be_falsey
      end
    end
  end

  describe "capture" do
    let(:variant) { create(:variant, price: 25) }
    let(:gift_card) { create(:gift_card, variant: variant) }
    let(:authorized_amount) { 13.0 }
    let(:auth_code) { gift_card.transactions.find_by(action: Spree::GiftCard::AUTHORIZE_ACTION, amount: authorized_amount).authorization_code }
    let(:order) { create(:order) }

    before do
      gift_card.authorize(authorized_amount)
      auth_code
    end

    def capture_payment
      gift_card.capture(capture_amount, auth_code, order_number: order.number)
    end

    context "when capture amount is less than authorized_amount" do
      let(:capture_amount) { 10.0 }

      it "expects not to return false" do
        expect(capture_payment).to be_truthy
      end

      it "expects to remove amount from authorization" do
        expect {
          capture_payment
        }.to change { gift_card.authorized_amount }.by(-capture_amount)
      end

      it "expects to remove amount from current_value" do
        expect {
          capture_payment
        }.to change { gift_card.current_value }.by(-capture_amount)
      end

      it "expects to create a capture transaction for the given amount" do
        capture_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::CAPTURE_ACTION, amount: capture_amount, authorization_code: auth_code, order: order).exists?).to be_truthy
      end
    end

    context "when capture amount is equal to authorized_amount" do
      let(:capture_amount) { 13.0 }

      it "expects not to return false" do
        expect(capture_payment).to be_truthy
      end

      it "expects to remove amount from authorization" do
        expect {
          capture_payment
        }.to change { gift_card.authorized_amount }.by(-capture_amount)
      end

      it "expects to remove amount from current_value" do
        expect {
          capture_payment
        }.to change { gift_card.current_value }.by(-capture_amount)
      end

      it "expects to create a capture transaction for the given amount" do
        capture_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::CAPTURE_ACTION, amount: capture_amount, authorization_code: auth_code, order: order).exists?).to be_truthy
      end
    end

    context "when capture amount is greater than authorized_amount" do
      let(:capture_amount) { 15.0 }

      it "expects to return false" do
        expect(capture_payment).to be_falsey
      end

      it "expects not to remove amount from authorization" do
        expect {
          capture_payment
        }.to_not change { gift_card.authorized_amount }
      end

      it "expects not to remove amount from current_value" do
        expect {
          capture_payment
        }.to_not change { gift_card.current_value }
      end

      it "expects not to create a capture transaction for the given amount" do
        capture_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::CAPTURE_ACTION, amount: capture_amount, authorization_code: auth_code, order: order).exists?).to be_falsey
      end
    end

    context "when authorization_code is invalid" do
      let(:capture_amount) { 10.0 }
      let(:auth_code) { super() + "123" }

      it "expects to return false" do
        expect(capture_payment).to be_falsey
      end

      it "expects not to remove amount from authorization" do
        expect {
          capture_payment
        }.to_not change { gift_card.authorized_amount }
      end

      it "expects not to remove amount from current_value" do
        expect {
          capture_payment
        }.to_not change { gift_card.current_value }
      end

      it "expects not to create a capture transaction for the given amount" do
        capture_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::CAPTURE_ACTION, amount: capture_amount, authorization_code: auth_code, order: order).exists?).to be_falsey
      end
    end
  end

  describe "void" do
    let(:variant) { create(:variant, price: 25) }
    let(:gift_card) { create(:gift_card, variant: variant) }
    let(:authorized_amount) { 13.0 }
    let(:auth_code) { gift_card.transactions.find_by(action: Spree::GiftCard::AUTHORIZE_ACTION, amount: authorized_amount).authorization_code }
    let(:order) { create(:order) }

    def void_payment
      gift_card.void(auth_code, order_number: order.number)
    end

    before do
      gift_card.authorize(authorized_amount)
      auth_code
    end

    context "when auth transaction present with auth code" do
      it "expects not to return false" do
        expect(void_payment).to be_truthy
      end

      it "expects to remove amount from authorized_amount" do
        expect {
          void_payment
        }.to change { gift_card.authorized_amount }.by(-authorized_amount)
      end

      it "expects to create a void transaction for the given amount" do
        void_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::VOID_ACTION, amount: authorized_amount, authorization_code: auth_code, order: order).exists?).to be_truthy
      end
    end

    context "when auth transaction not present with auth code" do
      let(:auth_code) { super() + "123" }

      it "expects to return false" do
        expect(void_payment).to be_falsey
      end

      it "expects not to remove amount from authorization" do
        expect {
          void_payment
        }.to_not change { gift_card.authorized_amount }
      end

      it "expects not to create a void transaction for the given amount" do
        void_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::VOID_ACTION, amount: authorized_amount, authorization_code: auth_code, order: order).exists?).to be_falsey
      end
    end
  end

  describe "credit" do
    let(:variant) { create(:variant, price: 25) }
    let(:gift_card) { create(:gift_card, variant: variant) }
    let(:captured_amount) { 13.0 }
    let(:auth_code) { gift_card.transactions.find_by(action: Spree::GiftCard::AUTHORIZE_ACTION, amount: captured_amount).authorization_code }
    let(:order) { create(:order) }

    before do
      gift_card.authorize(captured_amount)
      auth_code
      gift_card.capture(captured_amount, auth_code)
    end

    def credit_payment
      gift_card.credit(credit_amount, auth_code, order_number: order.number)
    end

    context "when credit amount is less than captured amount" do
      let(:credit_amount) { 10.0 }

      it "expects not to return false" do
        expect(credit_payment).to be_truthy
      end

      it "expects to add amount to current_value" do
        expect {
          credit_payment
        }.to change { gift_card.current_value }.by(credit_amount)
      end

      it "expects to create a credit transaction for the given amount" do
        credit_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::CREDIT_ACTION, amount: credit_amount, authorization_code: auth_code, order: order).exists?).to be_truthy
      end
    end

    context "when credit amount is equal to captured amount" do
      let(:credit_amount) { 13.0 }

      it "expects not to return false" do
        expect(credit_payment).to be_truthy
      end

      it "expects to add amount to current_value" do
        expect {
          credit_payment
        }.to change { gift_card.current_value }.by(credit_amount)
      end

      it "expects to create a credit transaction for the given amount" do
        credit_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::CREDIT_ACTION, amount: credit_amount, authorization_code: auth_code, order: order).exists?).to be_truthy
      end
    end

    context "when credit amount is greater than captured amount" do
      let(:credit_amount) { 15.0 }

      it "expects to return false" do
        expect(credit_payment).to be_falsey
      end

      it "expects not to add amount to current_value" do
        expect {
          credit_payment
        }.to_not change { gift_card.current_value }
      end

      it "expects not to create a credit transaction for the given amount" do
        credit_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::CREDIT_ACTION, amount: credit_amount, authorization_code: auth_code, order: order).exists?).to be_falsey
      end
    end

    context "when authorization_code is invalid" do
      let(:credit_amount) { 10.0 }
      let(:auth_code) { super() + "123" }

      it "expects to return false" do
        expect(credit_payment).to be_falsey
      end

      it "expects not to add amount to current_value" do
        expect {
          credit_payment
        }.to_not change { gift_card.current_value }
      end

      it "expects not to create a credit transaction for the given amount" do
        credit_payment
        expect(gift_card.transactions.where(action: Spree::GiftCard::CREDIT_ACTION, amount: credit_amount, authorization_code: auth_code, order: order).exists?).to be_falsey
      end
    end
  end

  context '#debit' do
    let(:gift_card) { create(:gift_card, variant: create(:variant, price: 25)) }
    let(:order) { create(:order) }

    it 'to raise an error when attempting to debit an amount higher than the current value' do
      expect(lambda {
        gift_card.debit(-30, order)
      }).to raise_error('Cannot debit gift card by amount greater than current value.')
    end

    it 'expects to subtract used amount from the current value and create a transaction' do
      gift_card.debit(-25, order)
      gift_card.reload # reload to ensure accuracy
      expect(gift_card.current_value.to_f).to eql(0.0)
      transaction = gift_card.transactions.first
      expect(transaction.amount.to_f).to eql(-25.0)
      expect(transaction.gift_card).to eql(gift_card)
      expect(transaction.order).to eql(order)
    end
  end

  context '#safely_redeem' do
    let(:variant) { create(:variant, price: 25) }
    let(:gift_card) { create(:gift_card, variant: variant, line_item: line_item) }
    let(:order) { create(:order) }
    let(:line_item) { create(:line_item, order: order, variant: variant) }
    let(:user) { order.user }
    let(:gift_card_category) { create(:gift_card_store_credit_category) }

    before do
      gift_card_category
      create(:secondary_credit_type)
      Spree::Config[:allow_gift_card_redeem] = true
      gift_card.update_column(:email, order.user.email)
      order.update_column(:completed_at, Time.current)
    end

    def safely_redeem
      gift_card.safely_redeem(user)
    end

    context "when gift_card_redemption is not allowed" do
      before do
        Spree::Config[:allow_gift_card_redeem] = false
      end

      it "expects to return false" do
        expect(safely_redeem).to be_falsey
      end

      it "expects to add error" do
        safely_redeem
        expect(gift_card.errors[:base]).to include(Spree.t('errors.gift_card.unauthorized'))
      end
    end

    context "when user is not present" do
      let(:user) { nil }

      it "expects to return false" do
        expect(safely_redeem).to be_falsey
      end

      it "expects to add error" do
        safely_redeem
        expect(gift_card.errors[:base]).to include(Spree.t('errors.gift_card.unauthorized'))
      end
    end

    context "when user email does not match gift card" do
      let(:user) { create(:user) }

      it "expects to return false" do
        expect(safely_redeem).to be_falsey
      end

      it "expects to add error" do
        safely_redeem
        expect(gift_card.errors[:base]).to include(Spree.t('errors.gift_card.unauthorized'))
      end
    end

    context "when amount_remaining is zero" do
      before do
        gift_card.update_column(:authorized_amount, gift_card.current_value)
      end

      it "expects to return false" do
        expect(safely_redeem).to be_falsey
      end

      it "expects to add error" do
        safely_redeem
        expect(gift_card.errors[:base]).to include(Spree.t('errors.gift_card.already_redeemed'))
      end
    end

    context "when order is not completed" do
      before do
        order.update_column(:completed_at, nil)
      end

      it "expects to return false" do
        expect(safely_redeem).to be_falsey
      end

      it "expects to add error" do
        safely_redeem
        expect(gift_card.errors[:base]).to include(Spree.t('errors.gift_card.unauthorized'))
      end
    end

    context "when valid redeem" do
      it "expects to return true" do
        expect(safely_redeem).to be_truthy
      end

      it "expects to add store credits to user's account" do
        safely_redeem
        expect(user.store_credits.where(category: gift_card_category, amount: 25.0).exists?).to be_truthy
      end

      it "expects to set current_value to zero" do
        safely_redeem
        expect(gift_card.current_value).to eq(0.0)
      end
    end
  end
end
