# Encapsulates feed information for a particular product.
class RetailerProductInfo
  attr_accessor :sku

  # Hash of English-language product info.
  attr_accessor :english_product_info

  # Hash of French-language product info.
  attr_accessor :french_product_info

  def initialize(sku, english_product_info, french_product_info)
    @sku = sku
    @english_product_info = english_product_info
    @french_product_info = french_product_info
  end

  # Returns product info hash for the specified language (or nil if info for that language 
  # does not exist).
  def get_info(language)
    case language
    when :french
      @french_product_info
    else
      @english_product_info
    end
  end

end

