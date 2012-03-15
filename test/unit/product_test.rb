require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  
  setup do
    Session.new
  end
  
  test "product caching" do
    product1 = create(:product)
    product2 = create(:product)
    retrieved_product = Product.cached(product1.id)
    retrieved_all_products = Product.manycached([product1.id, product2.id])

    assert_equal product1, retrieved_product, "retrieved product not the same as original"
    assert_not_nil retrieved_all_products.index(product1), "could not find project in cache"
    assert_not_nil retrieved_all_products.index(product2), "could not find project in cache"
  end

  test "Product and Spec import from BBY API" do
    sr = create(:scraping_rule, local_featurename: "longDescription", remote_featurename: "longDescription", rule_type: "Text")
    Product.feed_update
    # 20 created(Current BB page size), and 1 in the fixtures
    assert_equal 21, Product.count, "There should be 20 products created in the database"
    assert_equal true, Product.all.inject(true){|res,el|res && (el.instock || /^B/ =~ el.sku)}, "All products should be instock (unless they're bundles)"
    assert !Product.all[1].text_specs.empty?, "New products should have one texttspec"
  end
  
  test "Product and Spec import for bundles from BBY API" do
    sr = create(:scraping_rule, local_featurename: "price", remote_featurename: "regularPrice", rule_type: "Continuous")
    Product.feed_update
    # 20 created(Current BB page size), and 1 in the fixtures
    assert_equal 21, Product.count, "There should be 20 products created in the database"
    assert_equal true, Product.all.inject(true){|res,el|res && el.instock}, "All products should be instock"
    assert !Product.all[1].cont_specs.empty?, "New products should have one texttspec"
    assert_equal ["price"]*20, Product.all[1..-1].map{|p|p.cont_specs.first.try(:name)}, "Test that the price is available"
    assert_match /\d+(\.\d+)?/, Product.first.cont_specs.first.try(:value).to_s, "Prices are actually recorded correctly"
  end
  
  test "Product and spec update for special SKUs" do
    # feed_update again on skus which already exists in the products table and is for the proper retailer and product category
    # TODO: Product.feed_update twice, but with the products
    sr = create(:scraping_rule, local_featurename: 'product_type', remote_featurename: 'category_id', rule_type: "Categorical", regex: "(.*)/B\1")
    Product.feed_update
    Product.feed_update
    assert_equal 21, Product.count, "should have the same number of products after re-running the feed update with an unchanged feed"
  end
  
  test "Get Rules" do
    sr = create(:scraping_rule, local_featurename: "longDescription", remote_featurename: "longDescription")
    myrules = ScrapingRule.get_rules([],false)
    assert_equal sr, myrules.first[:rule], "Get Rules should return the singular rules in this case"
  end

end
