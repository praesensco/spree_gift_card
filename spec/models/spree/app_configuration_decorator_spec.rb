require "spec_helper"

describe Spree::AppConfiguration do
  it "expects to have preference allow_gift_card_redeem"  do
    expect(Spree::Config.has_preference?(:allow_gift_card_redeem)).to be_truthy
  end

  it "expects to set preference allow_gift_card_redeem default to true"  do
    expect(Spree::Config.allow_gift_card_redeem).to eq(true)
  end
end
