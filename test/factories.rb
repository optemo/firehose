FactoryGirl.define do
  factory :candidate do
    association :scraping_rule
    association :result
    association :scraping_correction
    product_id "100000A" #SKU
    parsed "value"
    raw "rawvalue"
  end
  factory :scraping_rule do
    local_featurename "title"
    remote_featurename "title"
    product_type "camera_bestbuy"
    rule_type "Categorical"
    regex ".*"
  end
  factory :result do
    product_type "camera_bestbuy"
    category "--[22474, 28382, 28381, 20220, 20218]"
    total 0
  end
  factory :product do
    title {|n| "Product#{n}"}
    association :cat_specs
    association :bin_specs
    association :cont_specs
    association :text_specs
    association :search_products
    association :product_siblings
    association :product_bundles
  end
  factory :scraping_correction do
    association :scraping_rule
    product_type "camera_bestbuy"
    raw "error--"
    corrected "good to go"
    product_id "100000B" #SKU
  end
  factory :cat_spec do
    association :product
  end
  factory :bin_spec do
    association :product
  end
  factory :cont_spec do
    association :product
  end
  factory :text_spec do
    association :product
  end
  factory :search_product do
    association :product
  end
  factory :product_siblings do
    association :product
  end
  factory :product_bundles do
    association :product
  end
end