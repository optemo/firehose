require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  
  setup do
    Session.new "B22474"
    Product.remove_missing_products_from_solr("B22474", {})

    # Create scraping rules
    sr = create(:scraping_rule, local_featurename: "product_type", remote_featurename: "category_id", rule_type: "Categorical", regex: '(.*)/B\1')
    sr = create(:scraping_rule, local_featurename: "title", remote_featurename: "name", rule_type: "Text")
    sr = create(:scraping_rule, local_featurename: "price", remote_featurename: "regularPrice", rule_type: "Continuous")
    sr = create(:scraping_rule, local_featurename: "saleprice", remote_featurename: "salePrice", rule_type: "Continuous")
    sr = create(:scraping_rule, local_featurename: "isAdvertised", remote_featurename: "isAdvertised", rule_type: "Binary", regex: '[Tt]rue/1')
    sr = create(:scraping_rule, local_featurename: "bundle", remote_featurename: "bundle", rule_type: "Text", regex: '(\[.+\])/\1')
    sr = create(:scraping_rule, local_featurename: "relations", remote_featurename: "related", rule_type: "Text", regex: '(\[.+\])/\1')

    # Create two scraping rules for same local feature
    sr = create(:scraping_rule, local_featurename: "color", remote_featurename: "longDescription", rule_type: "Categorical", regex: '[Bb]lue', priority: 0, bilingual: 1)
    sr = create(:scraping_rule, local_featurename: "color", remote_featurename: "longDescription", rule_type: "Categorical", regex: '[Bb]leu', priority: 0, bilingual: 1,
                                french: 1)
    sr = create(:scraping_rule, local_featurename: "color", remote_featurename: "longDescription", rule_type: "Categorical", regex: '[Oo]range', priority: 1)

    # Stub out BestBuyApi methods
    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474"), BBproduct.new(id: "222", category: "22474")])
    BestBuyApi.stubs(:product_search).with{|id, includeall, english| id == "111" and english}.returns(
      { "sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Blue).", "isAdvertised" => true}) 
    BestBuyApi.stubs(:product_search).with{|id, includeall, english| id == "111" and not english}.returns(
      { "sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Bleu).", "isAdvertised" => true}) 
    BestBuyApi.stubs(:product_search).with{|id| id == "222"}.returns(
      {"sku" => "222", "name" => "Test Product 222", "regularPrice" => 379.99, "longDescription" => "Description of product 222 (Orange).", "isAdvertised" => true}) 

    BestBuyApi.stubs(:get_shallow_product_infos).returns([
      {"sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Blue).", "isAdvertised" => true}, 
      {"sku" => "222", "name" => "Test Product 222", "regularPrice" => 379.99, "longDescription" => "Description of product 222 (Orange).", "isAdvertised" => true}
    ])

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
  
  test "If no new products and no changed specs, shallow update does not index anything" do
    Sunspot.expects(:index).at_least_once

    Product.feed_update

    Sunspot.expects(:index).never

    Product.feed_update(nil, true)
  end

  test "Feed_update should not throw exception for empty category" do 
    BestBuyApi.stubs(:category_ids).returns([])

    assert_nothing_raised("feed_update should not throw an exception") do
      Product.feed_update
    end
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
    assert_equal true, advertised_spec.value, "isAdvertised is true"

    search = Sunspot.search(Product) {
      keywords "111", :fields => ["sku"]
    }
    assert_equal 1, search.results.size, "Sunspot found the product"

  end

  test "Ensure feed_update stores translations" do
    # The following lines use Mocha to specify the calls we expect to be made to the I18n.backend.store_translations method.
    # At the end of the test, Mocha will verify these calls occurred inside of Product.feed_update.
    I18n.backend.expects(:store_translations).once.with { |locale, hash| locale = "en" and hash.size == 1 and hash["cat_option.B.color.blue"] == "Blue" }
    I18n.backend.expects(:store_translations).once.with { |locale, hash| locale = "fr" and hash.size == 1 and hash["cat_option.B.color.blue"] == "Bleu" }
    I18n.backend.expects(:store_translations).once.with { |locale, hash| locale = "en" and hash.size == 1 and hash["cat_option.B.color.orange"] == "Orange" }
    I18n.backend.expects(:store_translations).once.with { |locale, hash| locale = "en" and hash.size == 1 and hash["cat_option.B.product_type.b22474"] == "B22474" }
    Product.feed_update
  end

  test "Specs created/updated for existing products" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    price_spec = p111.cont_specs.find_by_name("price")
    assert_not_nil price_spec, "price spec was created"
    assert_equal 279.99, price_spec.value

    sale_price_spec = p111.cont_specs.find_by_name("saleprice")
    assert sale_price_spec.nil?, "sale price spec does not exist"

    BestBuyApi.stubs(:product_search).with{|id| id == "111"}.returns(
      {"sku" => "111", "name" => "Test Product 111 (elephants)", "regularPrice" => 179.99, "salePrice" => 149.99, 
       "longDescription" => "This is the description of product 111.", "isAdvertised" => true}) 

    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 still exists"
    assert p111.instock, "Product 111 is instock"

    price_spec = p111.cont_specs.find_by_name("price")
    assert_not_nil price_spec, "price spec still exists"
    assert_equal 179.99, price_spec.value, "price spec was updated"

    sale_price_spec = p111.cont_specs.find_by_name("saleprice")
    assert_not_nil sale_price_spec, "sale price spec was created"
    assert_equal 149.99, sale_price_spec.value

    search = Sunspot.search(Product) {
      keywords "elephants", :fields => ["title"]
    }
    assert_equal 1, search.results.size, "Sunspot found the product"

  end

  test "Upgrade to deep update if there are new products" do
    # Shallow update stubbed to *not* return isAdvertised spec.
    BestBuyApi.stubs(:get_shallow_product_infos).returns([
      {"sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Blue)."}, 
      {"sku" => "222", "name" => "Test Product 222", "regularPrice" => 379.99, "longDescription" => "Description of product 222 (Orange)."}
    ])

    Product.feed_update(nil, true)

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 exists"
    assert p111.instock, "Product 111 is instock"

    bin_spec = p111.bin_specs.find_by_name("isAdvertised")
    assert_not_nil bin_spec, "isAdvertised spec exists"
    assert_equal true, bin_spec.value, "isAdvertised is true"
  end

  test "Specs created/updated for existing products (shallow update)" do
    BestBuyApi.stubs(:product_search).with{|id| id == "111"}.returns(
      { "sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Blue).", "isAdvertised" => false}) 

    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    price_spec = p111.cont_specs.find_by_name("price")
    assert_not_nil price_spec, "price spec was created"
    assert_equal 279.99, price_spec.value

    sale_price_spec = p111.cont_specs.find_by_name("saleprice")
    assert sale_price_spec.nil?, "sale price spec does not exist"

    BestBuyApi.stubs(:get_shallow_product_infos).returns([
      {"sku" => "111", "name" => "Test Product 111 (elephants)", "regularPrice" => 179.99, "salePrice" => 149.99,
       "longDescription" => "This is the description of product 111.", "isAdvertised" => true} ])

    Sunspot.expects(:index).once.with { |products| products.size == 1 and products[0].sku == "111" }

    Product.feed_update(nil, true)

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 still exists"
    assert p111.instock, "Product 111 is instock"

    # Specs should have been created/updated by the shallow update.
    price_spec = p111.cont_specs.find_by_name("price")
    assert_not_nil price_spec, "price spec still exists"
    assert_equal 179.99, price_spec.value, "price spec was updated"

    sale_price_spec = p111.cont_specs.find_by_name("saleprice")
    assert_not_nil sale_price_spec, "sale price spec was created"
    assert_equal 149.99, sale_price_spec.value

    is_advertised_spec = p111.bin_specs.find_by_name("isAdvertised")
    assert_not_nil is_advertised_spec, "isAdvertised spec was created"
    assert_equal true, is_advertised_spec.value

    title_spec = p111.text_specs.find_by_name("title")
    assert_not_nil title_spec, "title spec still exists"
    assert_equal "Test Product 111 (elephants)", title_spec.value, "title spec was updated"

    # Verify that RuleOnSale was invoked.
    on_sale_spec = p111.bin_specs.find_by_name("onsale")
    assert_not_nil on_sale_spec, "onsale spec was created"
    assert on_sale_spec.value, "onsale is true"
  end

  test "Only specified custom rules are invoked for shallow update" do
    BestBuyApi.stubs(:product_search).with{|id| id == "111"}.returns(
      { "sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Blue).", "isAdvertised" => false}) 

    Product.feed_update

    BestBuyApi.stubs(:get_shallow_product_infos).returns([
      {"sku" => "111", "name" => "Test Product 111 (elephants)", "regularPrice" => 179.99, "salePrice" => 149.99,
       "longDescription" => "This is the description of product 111.", "isAdvertised" => true} ])

    RulePriceplusehf.expects(:compute).once
    RuleOnSale.expects(:compute).once
    RuleImageURLs.expects(:compute).never

    Product.feed_update(nil, true)
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

  test "Specs not deleted for shallow update" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    bin_spec = p111.bin_specs.find_by_name("isAdvertised")
    assert_not_nil bin_spec, "isAdvertised was created"
    assert_equal true, bin_spec.value, "isAdvertised is true"

    BestBuyApi.stubs(:get_shallow_product_infos).returns([
      {"sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Blue)."}, 
      {"sku" => "222", "name" => "Test Product 222", "regularPrice" => 379.99, "longDescription" => "Description of product 222 (Orange)."}
    ])

    Product.feed_update(nil, true)

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 still exists"
    assert p111.instock, "Product 111 is instock"

    bin_spec = p111.bin_specs.find_by_name("isAdvertised")
    assert_not_nil bin_spec, "isAdvertised still exists"
    assert_equal true, bin_spec.value, "isAdvertised is true"

  end

  test "Products not in the feed are deleted" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    p222 = Product.find_by_sku("222")
    assert_not_nil p222, "Product 222 was created"
    assert p222.instock, "Product 222 is instock"

    search = Sunspot.search(Product) {
      keywords "222", :fields => ["sku"]
    }
    assert_equal 1, search.results.size, "Sunspot found product 222"

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474")])

    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 exists"
    assert p111.instock, "Product 111 is instock"

    p222 = Product.find_by_sku("222")
    assert p222.nil?, "Product 222 no longer exists"

    search = Sunspot.search(Product) {
      keywords "222", :fields => ["sku"]
    }
    assert_equal 0, search.hits.size, "Sunspot did not find product 222"
  end

  test "Missing products are removed from Solr during full update" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"

    p222 = Product.find_by_sku("222")
    assert_not_nil p222, "Product 222 was created"

    p222.delete

    search = Sunspot.search(Product) {
      keywords "222", :fields => ["sku"]
    }
    assert_equal 1, search.hits.size, "Product 222 is present in Sunspot"

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474")])

    Product.feed_update

    search = Sunspot.search(Product) {
      keywords "222", :fields => ["sku"]
    }
    assert_equal 0, search.hits.size, "Product 222 was removed from Sunspot"

    search = Sunspot.search(Product) {
      keywords "111", :fields => ["sku"]
    }
    assert_equal 1, search.hits.size, "Product 111 is still present in Sunspot"
  end

  test "Remove missing products from Solr" do
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"

    search = Sunspot.search(Product) {
      keywords "222", :fields => ["sku"]
    }
    assert_equal 1, search.hits.size, "Product 222 is present in Sunspot"

    Product.remove_missing_products_from_solr("B22474", Set[p111.id])

    search = Sunspot.search(Product) {
      keywords "222", :fields => ["sku"]
    }
    assert_equal 0, search.hits.size, "Product 222 was removed from Sunspot"

    search = Sunspot.search(Product) {
      keywords "111", :fields => ["sku"]
    }
    assert_equal 1, search.hits.size, "Product 111 is still present in Sunspot"
  end

  test "Products not in the feed are deleted (shallow update)" do
    search = Sunspot.search(Product) {
      keywords "222", :fields => ["sku"]
    }
    assert_equal 0, search.hits.size, "Sunspot did not find product 222"

    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"
    assert p111.instock, "Product 111 is instock"

    p222 = Product.find_by_sku("222")
    assert_not_nil p222, "Product 222 was created"
    assert p222.instock, "Product 222 is instock"

    search = Sunspot.search(Product) {
      keywords "222", :fields => ["sku"]
    }
    assert_equal 1, search.results.size, "Sunspot found product 222"

    BestBuyApi.stubs(:get_shallow_product_infos).returns([
      {"sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Blue).", "isAdvertised" => true}
    ])

    Product.feed_update(nil, true)

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 exists"
    assert p111.instock, "Product 111 is instock"

    p222 = Product.find_by_sku("222")
    assert p222.nil?, "Product 222 no longer exists"

    search = Sunspot.search(Product) {
      keywords "222", :fields => ["sku"]
    }
    assert_equal 0, search.hits.size, "Sunspot did not find product 222"
  end

  test "Large categories are protected from empty feeds" do
    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474"), BBproduct.new(id: "222", category: "22474"),
                                             BBproduct.new(id: "333", category: "22474"), BBproduct.new(id: "444", category: "22474")])
    ["111", "222", "333", "444"].each do |test_sku| 
      BestBuyApi.stubs(:product_search).with{|id| id == test_sku}.returns(
          { "sku" => test_sku, "name" => "Test Product " + test_sku, "regularPrice" => 279.99, "longDescription" => "Description of product " + test_sku}) 
    end
    Product.feed_update

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 was created"

    BestBuyApi.stubs(:category_ids).returns([])

    assert_raise ValidationError, "Product.feed_update throws a ValidationError" do
      Product.feed_update
    end

    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 is still in the database"

  end

  test "product_bundles is cleaned up when *bundle product* is removed from feed" do
    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474"), BBproduct.new(id: "111-bundle", category: "22474"),
                                             BBproduct.new(id: "222", category: "22474")])
    BestBuyApi.stubs(:product_search).with{|id| id == "111-bundle"}.returns(
      { "sku" => "111-bundle", "name" => "Bundle 111", "regularPrice" => 279.99, "longDescription" => "Description.", "isAdvertised" => true, "bundle" => '[{"sku": "111"}]'}) 

    Product.feed_update
    
    p111Bundle = Product.find_by_sku("111-bundle")
    assert_not_nil p111Bundle, "Product 111-bundle exists"

    bundles = ProductBundle.find_all_by_bundle_id(p111Bundle.id)

    assert_equal 1, bundles.size, "One entry exists in product_bundles table for product 111-bundle"

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474"), BBproduct.new(id: "222", category: "22474")])

    Product.feed_update 

    bundles = ProductBundle.find_all_by_bundle_id(p111Bundle.id)

    assert_equal 0, bundles.size, "Zero entries exist in product_bundles table for product 111-bundle"
  
  end

  test "product_bundles is cleaned up when *product in bundle* is removed from feed" do
    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474"), BBproduct.new(id: "111-bundle", category: "22474"),
                                             BBproduct.new(id: "222", category: "22474")])
    BestBuyApi.stubs(:product_search).with{|id| id == "111-bundle"}.returns(
      { "sku" => "111-bundle", "name" => "Bundle 111", "regularPrice" => 279.99, "longDescription" => "Description.", "isAdvertised" => true, "bundle" => '[{"sku": "111"}]'}) 

    Product.feed_update
    
    p111 = Product.find_by_sku("111")
    assert_not_nil p111, "Product 111 exists"

    bundles = ProductBundle.find_all_by_product_id(p111.id)

    assert_equal 1, bundles.size, "One entry exists in product_bundles table for product 111"

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111-bundle", category: "22474"), BBproduct.new(id: "222", category: "22474")])

    Product.feed_update 

    bundles = ProductBundle.find_all_by_product_id(p111.id)

    assert_equal 0, bundles.size, "Zero entries exist in product_bundles table for product 111"
  
  end

  test "product_siblings is cleaned up when product is removed from feed" do
    BestBuyApi.stubs(:product_search).with{|id| id == "111"}.returns(
      { "sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description.", "isAdvertised" => true, 
        "related" => '[{"sku": "222", "type": "Variant"}]'}) 

    Product.feed_update

    p111 = Product.find_by_sku("111")

    p111Siblings = ProductSibling.find_all_by_product_id(p111.id)

    assert_equal 1, p111Siblings.size, "One entry exists in product_siblings table for product 111 as product"
 
    p111AsSibling = ProductSibling.find_all_by_sibling_id(p111.id)

    assert_equal 1, p111AsSibling.size, "One entry exists in product_siblings table for product 111 as sibling"

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "222", category: "22474")])

    Product.feed_update

    p111Siblings = ProductSibling.find_all_by_product_id(p111.id)

    assert_equal 0, p111Siblings.size, "Zero entries exist in product_siblings table for product 111 as product"
 
    p111AsSibling = ProductSibling.find_all_by_sibling_id(p111.id)

    assert_equal 0, p111AsSibling.size, "Zero entries exist in product_siblings table for product 111 as sibling"

  end

  test "Equivalence is deleted when product is removed from feed" do
    Product.feed_update

    p222 = Product.find_by_sku("222")
    equivalences = Equivalence.find_all_by_product_id(p222.id)

    assert_equal 1, equivalences.size, "One equivalence row exists for product 222"

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474")])

    Product.feed_update

    equivalences = Equivalence.find_all_by_product_id(p222.id)

    assert_equal 0, equivalences.size, "Zero equivalence rows exist for product 222"

  end

  test "Product deleted if product_search raises error" do
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
    assert p222.nil?, "Product 222 no longer exists"
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

    BestBuyApi.stubs(:category_ids).returns([BBproduct.new(id: "111", category: "22474"), 
                                             BBproduct.new(id: "222", category: "22474"), BBproduct.new(id: "444555", category: "22474")])
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

  test "Product category changes (shallow update)" do 
    product = create(:product, sku: "444555", instock: true, retailer: "B")
    create(:cat_spec, product: product, name: "product_type", value: "B28381")

    Product.feed_update

    product_count = Product.count

    product = Product.find_by_sku("444555")
    assert_not_nil product, "Product 444555 exists"

    product_type_spec = product.cat_specs.find_by_name("product_type")
    assert_not_nil product_type_spec, "product_type spec exists"
    assert_equal "B28381", product_type_spec.value, "Product type is B28381"

    BestBuyApi.stubs(:get_shallow_product_infos).returns([
      {"sku" => "111", "name" => "Test Product 111", "regularPrice" => 279.99, "longDescription" => "Description of product 111 (Orange, Blue).", "isAdvertised" => true}, 
      {"sku" => "222", "name" => "Test Product 222", "regularPrice" => 379.99, "longDescription" => "Description of product 222 (Orange).", "isAdvertised" => true},
      {"sku" => "444555", "name" => "Test Product 444555", "regularPrice" => 379.99, "longDescription" => "Description of product 444555.", "isAdvertised" => true} 
    ])

    BestBuyApi.stubs(:product_search).with{|id| id == "444555"}.returns(
      {"sku" => "444555", "name" => "Test Product 444555", "regularPrice" => 379.99, "longDescription" => "Description of product 444555.", "isAdvertised" => true}) 

    # Will upgrade to deep update.
    Product.feed_update(nil, true)

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
    create(:cat_spec, product: product, name: "product_type", value: "B22474")

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
