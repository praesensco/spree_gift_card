require 'spec_helper'

describe Spree::PaymentMethod::GiftCard do
  let(:order) { create(:order) }
  let(:payment) { create(:payment, order: order) }
  let(:gateway_options) { payment.gateway_options }

  context '#authorize' do
    subject do
      Spree::PaymentMethod::GiftCard.new.authorize(auth_amount, gift_card, gateway_options)
    end

    let(:auth_amount) { gift_card.amount_remaining * 100 }
    let(:gift_card) { create(:gift_card) }

    context 'with an invalid gift card' do
      let(:gift_card) { nil }
      let(:auth_amount) { 10 }

      it 'declines an unknown gift card' do
        is_expected.to_not be_success
      end

      it 'adds unable_to_find message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.unable_to_find')
      end
    end

    context 'with insuffient funds' do
      let(:auth_amount) { (gift_card.amount_remaining * 100) + 1 }

      it 'declines a gift card' do
        is_expected.to_not be_success
      end

      it 'adds insufficient_funds message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.insufficient_funds')
      end
    end

    context 'with a valid request' do
      it 'authorizes a valid gift card' do
        is_expected.to be_success
      end

      it 'adds a authorization code' do
        expect(subject.authorization).to_not be_nil
      end
    end
  end

  context '#capture' do
    subject do
      Spree::PaymentMethod::GiftCard.new.capture(capture_amount, auth_code, gateway_options)
    end

    let(:capture_amount) { 10_00 }
    let(:auth_code) { gift_card_transaction.authorization_code }

    let(:authorized_amount) { capture_amount / 100.0 }
    let(:gift_card_transaction) { create(:gift_card_transaction, gift_card: gift_card, amount: authorized_amount, action: Spree::GiftCard::AUTHORIZE_ACTION) }
    let(:gift_card) { create(:gift_card, current_value: authorized_amount, authorized_amount: authorized_amount) }

    context 'with an invalid auth code' do
      let(:auth_code) { -1 }

      it 'declines an unknown gift card' do
        is_expected.to_not be_success
      end

      it 'adds unable_to_find message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.unable_to_find')
      end
    end

    context 'when unable to authorize the amount' do
      let(:authorized_amount) { (capture_amount - 1) / 100 }

      before do
        allow_any_instance_of(Spree::GiftCard).to receive(:authorize).and_return(true)
      end

      it 'declines a gift card' do
        is_expected.to_not be_success
      end

      it 'adds insufficient_authorized_amount message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.insufficient_authorized_amount')
      end
    end

    context 'with a valid request' do
      it 'captures the gift card' do
        is_expected.to be_success
      end

      it 'adds successful_action capture message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.successful_action',
                                                   action: Spree::GiftCard::CAPTURE_ACTION)
      end
    end
  end

  context '#void' do
    subject do
      Spree::PaymentMethod::GiftCard.new.void(auth_code, gateway_options)
    end

    let(:auth_code) { gift_card_transaction.authorization_code }
    let(:gift_card_transaction) { create(:gift_card_transaction, action: Spree::GiftCard::AUTHORIZE_ACTION) }

    context 'with an invalid auth code' do
      let(:auth_code) { 1 }

      it 'declines an unknown gift card' do
        is_expected.to_not be_success
      end

      it 'adds unable_to_find message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.unable_to_find')
      end
    end

    context 'when the gift card is not voided successfully' do
      before { allow_any_instance_of(Spree::GiftCard).to receive(:void).and_return false }

      it 'returns an error response' do
        is_expected.to_not be_success
      end
    end

    it 'voids the gift card' do
      is_expected.to be_success
    end

    it 'adds successful_action void message' do
      expect(subject.message).to include Spree.t('gift_card_payment_method.successful_action',
                                                 action: Spree::GiftCard::VOID_ACTION)
    end
  end

  context '#purchase' do
    subject do
      Spree::PaymentMethod::GiftCard.new.purchase(auth_amount, gift_card, gateway_options)
    end

    let(:auth_amount) { gift_card.amount_remaining * 100 }
    let(:gift_card) { create(:gift_card) }

    context 'with an invalid gift card' do
      let(:gift_card) { nil }
      let(:auth_amount) { 10 }

      it 'declines an unknown gift card' do
        is_expected.to_not be_success
      end

      it 'adds unable_to_find message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.unable_to_find')
      end
    end

    context 'with insuffient funds' do
      let(:auth_amount) { (gift_card.amount_remaining * 100) + 1 }

      it 'declines a gift card' do
        is_expected.to_not be_success
      end

      it 'adds insufficient_funds message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.insufficient_funds')
      end
    end

    context 'with a valid request' do
      it 'purchases a valid gift card purchase request' do
        is_expected.to be_success
      end

      it 'adds a authorization code' do
        expect(subject.authorization).to_not be_nil
      end
    end
  end

  context '#credit' do
    subject do
      Spree::PaymentMethod::GiftCard.new.credit(credit_amount, auth_code, gateway_options)
    end

    let(:credit_amount) { gift_card.authorized_amount * 100 }
    let(:auth_code) { gift_card_transaction.authorization_code }
    let(:gift_card_transaction) { create(:gift_card_transaction, gift_card: gift_card, amount: gift_card.authorized_amount, action: Spree::GiftCard::CAPTURE_ACTION) }
    let(:gift_card) { create(:gift_card) }

    context 'with an invalid auth code' do
      let(:auth_code) { -1 }

      it 'declines an unknown gift card' do
        is_expected.to_not be_success
      end

      it 'adds unable_to_find message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.unable_to_find')
      end
    end

    context 'with overcredit amount' do
      let(:credit_amount) { (gift_card.authorized_amount * 100) + 1 }

      it 'declines a gift card' do
        is_expected.to_not be_success
      end

      it 'adds unable_to_credit message' do
        expect(subject.message).to include Spree.t('gift_card_payment_method.unable_to_credit', auth_code: auth_code)
      end
    end

    context 'with a valid request' do
      it 'credits a valid gift card credit request' do
        is_expected.to be_success
      end

      it 'adds a authorization code' do
        expect(subject.authorization).to_not be_nil
      end
    end
  end
end
