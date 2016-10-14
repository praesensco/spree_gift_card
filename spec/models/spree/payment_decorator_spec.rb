require 'spec_helper'

describe Spree::Payment, type: :model do

  describe 'delegate' do
    it { is_expected.to delegate_method(:gift_card?).to(:payment_method) }
  end

  describe ".gift_cards" do
    context "when payment using gift_card" do
      let!(:payment) { create(:gift_card_payment) }

      it "expects to be included in gift_cards payments" do
        expect(Spree::Payment.gift_cards).to include(payment)
      end
    end

    context "when payment not using gift_card" do
      let!(:payment) { create(:payment) }

      it "expects not to be included in gift_cards payments" do
        expect(Spree::Payment.gift_cards).not_to include(payment)
      end
    end
  end

  describe "#store_credit_or_gift_card?" do
    context "when payment using gift_card" do
      let!(:payment) { create(:gift_card_payment) }

      it "expects to be true" do
        expect(payment.store_credit_or_gift_card?).to be_truthy
      end
    end

    context "when payment using store_credit" do
      let!(:payment) { create(:store_credit_payment) }

      it "expects to be true" do
        expect(payment.store_credit_or_gift_card?).to be_truthy
      end
    end

    context "when payment using neither store_credit nor gift_card" do
      let!(:payment) { create(:payment) }

      it "expects to be false" do
        expect(payment.store_credit_or_gift_card?).to be_falsey
      end
    end
  end
end
