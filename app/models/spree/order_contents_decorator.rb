Spree::OrderContents.class_eval do
  def grab_line_item_by_variant_with_gift_card(variant, raise_error = false, options = {})
    return if variant.product.is_gift_card?

    grab_line_item_by_variant_without_gift_card(variant, raise_error, options)
  end
  alias_method_chain :grab_line_item_by_variant, :gift_card
end
