Spree::AppConfiguration.class_eval do
  preference :allow_gift_card_redeem, :boolean, default: true
end
