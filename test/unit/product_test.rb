require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  
  setup do
    Session.new "B22474"

    # Create scraping rules
    sr = create(:scraping_rule, local_featurename: "product_type", remote_featurename: "category_id", rule_type: "Categorical", regex: '(.*)/B\1')
    sr = create(:scraping_rule, local_featurename: "title", remote_featurename: "name", rule_type: "Text")
    sr = create(:scraping_rule, local_featurename: "price", remote_featurename: "regularPrice", rule_type: "Continuous")
    sr = create(:scraping_rule, local_featurename: "isAdvertised", remote_featurename: "isAdvertised", rule_type: "Binary", regex: '[Tt]rue/1')

    # Create two scraping rules for same local feature
    sr = create(:scraping_rule, local_featurename: "color", remote_featurename: "longDescription", rule_type: "Categorical", regex: '[Bb]lue', priority: 0)
    sr = create(:scraping_rule, local_featurename: "color", remote_featurename: "longDescription", rule_type: "Categorical", regex: '[Oo]range', priority: 1)

    # Stub out BestBuyApi methods
    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474"), BBproduct.new(id: "222", category: "22474")])
    BestBuyApi.stubs(:product_search).with{|id| id == "111"}.returns(
      {"sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Blue).", "isAdvertised" => true}) 
    BestBuyApi.stubs(:product_search).with{|id| id == "222"}.returns(
      {"sku" => "222", "name" => "Test Product 222", "regularPrice" => 379.99, "longDescription" => "Description of product 222 (Orange).", "isAdvertised" => true}) 

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

  test "Calling feed_update twice with unchanged feed" do
    Product.feed_update

    product_count = Product.count

    Product.feed_update

    assert_equal product_count, Product.count, "should have the same number of products after re-running the feed update with an unchanged feed"
  end
  
  test "Instock set and specs created for new products" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    product_type_spec = p111.cat_specs.find_by_name("product_type")
    assert_not_nil product_type_spec, "product_type spec was created"
    assert_equal "B22474", product_type_spec.value, "Product type is B22474"

    title_spec = p111.text_specs.find_by_name("title")
    assert_not_nil title_spec, "title spec was created"
    assert_equal "Test Product 111", title_spec.value

    price_spec = p111.cont_specs.find_by_name("price")
    assert_not_nil price_spec, "price spec was created"
    assert_equal 279.99, price_spec.value

    advertised_spec = p111.bin_specs.find_by_name("isAdvertised")
    assert_not_nil advertised_spec, "isAdvertised spec was created"
    assert_equal true, advertised_spec.value

    search = Sunspot.search(Product) {
      keywords "111", :fields => ["sku"]
    }
    assert_equal 1, search.results.size, "Sunspot found the product"

  end

  test "Specs updated for existing products" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    price_spec = p111.cont_specs.find_by_name("price")
    assert_not_nil price_spec, "price spec was created"
    assert_equal 279.99, price_spec.value

    BestBuyApi.stubs(:product_search).with{|id| id == "111"}.returns(
      {"sku" => "111", "name" => "Test Product 111 (elephants)", "regularPrice" => 179.99, "longDescription" => "This is the description of product 111.", "isAdvertised" => true}) 

    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 still exists"
    assert p111.instock, "Product 111 is instock"

    price_spec = p111.cont_specs.find_by_name("price")
    assert_not_nil price_spec, "price spec still exists"
    assert_equal 179.99, price_spec.value, "price spec was updated"

    search = Sunspot.search(Product) {
      keywords "elephants", :fields => ["title"]
    }
    assert_equal 1, search.results.size, "Sunspot found the product"

  end

  test "Specs deleted if they are no longer in the feed" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    price_spec = p111.cont_specs.find_by_name("price")
    assert_not_nil price_spec, "price spec was created"
    assert_equal 279.99, price_spec.value

    BestBuyApi.stubs(:product_search).with{|id| id == "111"}.returns(
      {"sku" => "111", "name" => "Test Product 111", "longDescription" => "This is the description of product 111.", "isAdvertised" => true}) 

    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 still exists"
    assert p111.instock, "Product 111 is instock"

    price_spec = p111.cont_specs.find_by_name("price")
    assert price_spec.nil?, "price spec was deleted"

  end

  test "Instock set to false for products not in the feed" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    p222 = Product.find_by_sku("222")
    assert_not_nil p222, "Product 222 was created"
    assert p222.instock, "Product 222 is instock"

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474")])

    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 exists"
    assert p111.instock, "Product 111 is instock"

    p222 = Product.find_by_sku("222")
    assert_not_nil p222, "Product 222 exists"
    assert !p222.instock, "Product 222 is not instock"
  end

  test "Instock set to false if product_search raises error" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    p222 = Product.find_by_sku("222")
    assert_not_nil p222, "Product 222 was created"
    assert p222.instock, "Product 222 is instock"

    BestBuyApi.stubs(:product_search).with{|id| id == "222"}.raises(BestBuyApi::RequestError)

    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 exists"
    assert p111.instock, "Product 111 is instock"

    p222 = Product.find_by_sku("222")
    assert_not_nil p222, "Product 222 exists"
    assert !p222.instock, "Product 222 is not instock"
  end

  test "Multiple scraping rules applied in priority order" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"

    color_spec = p111.cat_specs.find_by_name("color")
    assert_not_nil color_spec, "color spec was created"
    assert_equal "blue", color_spec.value, "rule for blue took precedence over rule for orange"

    p222 = Product.find_by_sku("222")
    assert_not_nil p222, "Product 222 was created"

    color_spec = p222.cat_specs.find_by_name("color")
    assert_not_nil color_spec, "color spec was created"
    assert_equal "orange", color_spec.value, "rule for blue failed to match and rule for orange matched"

  end

  test "Product category changes" do 
    product = create(:product, sku: "444555", instock: true, retailer: "B")
    create(:cat_spec, product: product, name: "product_type", value: "B28381")

    Product.feed_update

    product_count = Product.count

    product = Product.find_by_sku("444555")
    assert_not_nil product, "Product 444555 exists"

    product_type_spec = product.cat_specs.find_by_name("product_type")
    assert_not_nil product_type_spec, "product_type spec exists"
    assert_equal "B28381", product_type_spec.value, "Product type is B28381"

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474"), BBproduct.new(id: "222", category: "22474"), BBproduct.new(id: "444555", category: "22474")])
    BestBuyApi.stubs(:product_search).with{|id| id == "444555"}.returns(
      {"sku" => "444555", "name" => "Test Product 444555", "regularPrice" => 379.99, "longDescription" => "Description of product 444555.", "isAdvertised" => true}) 

    Product.feed_update

    assert_equal product_count, Product.count, "total number of products did not change"
    
    product = Product.find_by_sku("444555")
    assert_not_nil product, "Product 444555 exists"

    product_type_spec = product.cat_specs.find_by_name("product_type")
    assert_not_nil product_type_spec, "product_type spec exists"
    assert_equal "B22474", product_type_spec.value, "Product type is B22474"
  end

  test "Duplicate specs are cleaned up" do
    # Create product with two product_type specs
    product = create(:product, sku: "333444", instock: true, retailer: "B")
    create(:cat_spec, product: product, name: "product_type", value: "B28381")
    create(:cat_spec, product: product, name: "product_type", value: "B28382")

    product = Product.find_by_sku("333444")
    assert_not_nil product, "Product 333444 exists"

    type_specs = product.cat_specs.where(:name => "product_type")
    
    assert_equal 2, type_specs.size, "Product has two product_type specs"

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474"), BBproduct.new(id: "222", category: "22474"), 
                                            BBproduct.new(id: "333444", category: "22474")])
    BestBuyApi.stubs(:product_search).with{|id| id == "333444"}.returns(
      {"sku" => "333444", "name" => "Test Product 333444", "regularPrice" => 279.99, "longDescription" => "This is the description of product 333444.", "isAdvertised" => true}) 

    Product.feed_update

    product = Product.find_by_sku("333444")
    assert_not_nil product, "Product 333444 exists"
    type_specs = product.cat_specs.where(:name => "product_type")
    assert_equal 1, type_specs.size, "Product has only one product_type spec"
    assert_equal "B22474", type_specs[0].value, "product_type is updated to B22474"
  end

  test "Dirty Bit" do
    p = create(:product, instock: false)
    assert_false p.dirty?, "New products should not be dirty"
    p.instock = true
    assert p.dirty?, "Changed products should be dirty"
    p2 = create(:product)
    p2.set_dirty
    assert p.dirty?, "Tainted products should be dirty"
  end

end
