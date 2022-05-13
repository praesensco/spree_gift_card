module Spree
  module AppConfigurationDecorator

    def self.prepended(base)
      base.preference :allow_gift_card_redeem, :boolean, default: true
    end
    # preference :allow_gift_card_redeem, :boolean, default: true
  end
end

::Spree::AppConfiguration.prepend(Spree::AppConfigurationDecorator)