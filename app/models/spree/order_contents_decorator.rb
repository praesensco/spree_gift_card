Spree::OrderContents.class_eval do

  alias_method :orig_grab_line_item_by_variant, :grab_line_item_by_variant

  def grab_line_item_by_variant(variant, raise_error = false, args = {})
    raise_error = args[0] || false

    if variant.product.is_gift_card?
      line_item = nil
    else
      line_item = order.find_line_item_by_variant(variant)
    end

    if !line_item.present? && raise_error
      raise ActiveRecord::RecordNotFound, "Line item not found for variant #{variant.sku}"
    end

    line_item
  end

end
