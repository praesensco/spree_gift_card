require 'spec_helper'

describe 'Order' do
  describe '#add_gift_card_payments' do
    let(:order_total) { 500.00 }
    let(:gift_card) { create(:gift_card) }
    let(:gift_card_code) { "gc123" }

    before { create(:gift_card_payment_method) }

    subject { order.add_gift_card_payments(gift_card) }

    context 'there is no gift card' do
      let(:gift_card) { nil }
      let(:order) { create(:order, total: order_total) }

      before do
        order.update_column(:total, order_total)
        subject
        order.reload
      end

      it 'does not create a gift card payment' do
        expect(order.payments.count).to eq 0
      end
    end

    context 'gift card has sufficient amount to pay for the entire order' do
      let(:variant) { create(:variant, price: order_total) }
      let(:gift_card) { create(:gift_card, code: gift_card_code, variant: variant) }
      let(:order) { create(:order, total: order_total) }

      before do
        gift_card
        subject
        order.reload
      end

      it 'creates a single payment' do
        expect(order.payments.count).to eq 1
      end

      it 'creates a gift_card payment' do
        expect(order.payments.first).to be_gift_card
      end

      it 'creates a payment for the full amount' do
        expect(order.payments.first.amount).to eq order_total
      end
    end

    context 'the available store credit is not enough to pay for the entire order' do
      let(:expected_cc_total) { 100.0 }
      let(:gift_card_total) { order_total - expected_cc_total }
      let(:variant) { create(:variant, price: gift_card_total) }
      let(:gift_card) { create(:gift_card, code: gift_card_code, variant: variant) }
      let(:order) { create(:order, total: order_total) }

      before do
        order.update_column(:total, order_total)
        gift_card
        subject
        order.reload
      end

      it 'creates a single payment' do
        expect(order.payments.count).to eq 1
      end

      it 'creates a gift_card payment' do
        expect(order.payments.first).to be_gift_card
      end

      it 'creates a payment for the available amount' do
        expect(order.payments.first.amount).to eq gift_card_total
      end
    end
  end

  describe '#order_total_after_store_credit' do
    let(:order_total) { 100.0 }
    let(:order) { create(:order, total: order_total) }

    subject { order }

    before do
      create(:gift_card_payment_method)
      allow(subject).to receive(:total_applicable_store_credit).and_return(applicable_store_credit)
    end

    context "order's user has store credits" do
      let(:applicable_store_credit) { 10.0 }

      it 'deducts the applicable store credit' do
        expect(subject.order_total_after_store_credit).to eq (order_total - applicable_store_credit)
      end
    end

    context "order has gift card payments" do
      let(:gift_card_code) { "gc123" }
      let(:gift_card_total) { 20.0 }
      let(:variant) { create(:variant, price: gift_card_total) }
      let(:gift_card) { create(:gift_card, code: gift_card_code, variant: variant) }
      let(:applicable_store_credit) { 0.0 }

      subject { order }

      before do
        order.update_column(:total, order_total)
        gift_card
        order.add_gift_card_payments(gift_card)
        order.reload
      end

      it 'deducts the applicable gift card payment amount' do
        expect(subject.order_total_after_store_credit).to eq (order_total - gift_card_total)
      end

      context "order's user has store credits" do
        let(:applicable_store_credit) { 10.0 }

        it 'deducts the applicable store credit' do
          expect(subject.order_total_after_store_credit).to eq (order_total - applicable_store_credit - gift_card_total)
        end
      end
    end

    context "order's user does not have any store credits" do
      let(:applicable_store_credit) { 0.0 }

      it 'returns the order total' do
        expect(order.order_total_after_store_credit).to eq order_total
      end
    end
  end

  describe '#total_applied_gift_card' do
    context 'with valid payments' do
      let(:order) { payment.order }
      let!(:payment) { create(:gift_card_payment) }
      let!(:second_payment) { create(:gift_card_payment, order: order) }

      subject { order }

      it 'returns the sum of the payment amounts' do
        expect(subject.total_applied_gift_card).to eq (payment.amount + second_payment.amount)
      end
    end

    context 'without valid payments' do
      let(:order) { create(:order) }

      subject { order }

      it 'returns 0' do
        expect(subject.total_applied_gift_card).to be_zero
      end
    end
  end

  describe '#using_gift_card?' do
    subject { create(:order) }

    context 'order has gift card payment' do
      before { allow(subject).to receive(:total_applied_gift_card).and_return(10.0) }
      it { expect(subject.using_gift_card?).to be true }
    end

    context 'order has no gift card payments' do
      before { allow(subject).to receive(:total_applied_gift_card).and_return(0.0) }
      it { expect(subject.using_gift_card?).to be false }
    end
  end

  describe '#display_total_applied_gift_card' do
    let(:total_applied_gift_card) { 10.00 }

    subject { create(:order) }

    before do
      allow(subject).to receive(:total_applied_gift_card).and_return(total_applied_gift_card)
    end

    it 'returns a money instance' do
      expect(subject.display_total_applied_gift_card).to be_a(Spree::Money)
    end

    it 'returns a negative amount' do
      expect(subject.display_total_applied_gift_card.money.cents).to eq (total_applied_gift_card * -100.0)
    end
  end

  describe '#add_store_credit_payments' do
    let(:order_total) { 500.00 }

    before { create(:store_credit_payment_method) }

    subject { order.add_store_credit_payments }

    context 'there is no store credit' do
      let(:order) { create(:store_credits_order_without_user, total: order_total) }

      before do
        # callbacks recalculate total based on line items
        # this ensures the total is what we expect
        order.update_column(:total, order_total)
        subject
        order.reload
      end

      it 'does not create a store credit payment' do
        expect(order.payments.count).to eq 0
      end
    end

    context 'there is enough store credit to pay for the entire order' do
      let(:store_credit) { create(:store_credit, amount: order_total) }
      let(:order) { create(:order, user: store_credit.user, total: order_total) }

      before do
        subject
        order.reload
      end

      it 'creates a store credit payment for the full amount' do
        expect(order.payments.count).to eq 1
        expect(order.payments.first).to be_store_credit
        expect(order.payments.first.amount).to eq order_total
      end
    end

    context 'the available store credit is not enough to pay for the entire order' do
      let(:expected_cc_total) { 100.0 }
      let(:store_credit_total) { order_total - expected_cc_total }
      let(:store_credit) { create(:store_credit, amount: store_credit_total) }
      let(:order) { create(:order, user: store_credit.user, total: order_total) }

      before do
        # callbacks recalculate total based on line items
        # this ensures the total is what we expect
        order.update_column(:total, order_total)
        subject
        order.reload
      end

      it 'creates a store credit payment for the available amount' do
        expect(order.payments.count).to eq 1
        expect(order.payments.first).to be_store_credit
        expect(order.payments.first.amount).to eq store_credit_total
      end

      context "order has gift card payments" do
        let(:gift_card_code) { "gc123" }
        let(:gift_card_total) { 20.0 }
        let(:variant) { create(:variant, price: gift_card_total) }
        let(:gift_card) { create(:gift_card, code: gift_card_code, variant: variant) }

        before do
          create(:gift_card_payment_method)
          order.update_column(:total, order_total)
          gift_card
          order.add_gift_card_payments(gift_card)
          order.reload
        end

        it 'creates a gift card payment for the available amount' do
          expect(order.payments.count).to eq 2
          expect(order.payments.last).to be_gift_card
          expect(order.payments.last.amount).to eq gift_card_total
        end
      end
    end

    context 'there are multiple store credits' do
      context 'they have different credit type priorities' do
        let(:amount_difference) { 100 }
        let!(:primary_store_credit) { create(:store_credit, amount: (order_total - amount_difference)) }
        let!(:secondary_store_credit) do
          create(:store_credit, amount: order_total, user: primary_store_credit.user,
                                credit_type: create(:secondary_credit_type))
        end
        let(:order) { create(:order, user: primary_store_credit.user, total: order_total) }

        before do
          Timecop.scale(3600)
          subject
          order.reload
        end

        after { Timecop.return }

        it 'uses the primary store credit type over the secondary' do
          primary_payment = order.payments.first
          secondary_payment = order.payments.last

          expect(order.payments.size).to eq 2
          expect(primary_payment.source).to eq primary_store_credit
          expect(secondary_payment.source).to eq secondary_store_credit
          expect(primary_payment.amount).to eq(order_total - amount_difference)
          expect(secondary_payment.amount).to eq(amount_difference)
        end
      end
    end
  end
end
