FactoryGirl.define do
  factory :candidate do
    association :scraping_rule
    association :scraping_correction
    sku "100000A"
    parsed "value"
    raw "rawvalue"
  end
  factory :scraping_rule do
    local_featurename "title"
    remote_featurename "title"
    product_type "camera_bestbuy"
    rule_type "Categorical"
    regex ".*"
    active true
  end
  factory :result do
    product_type "camera_bestbuy"
    category "--[22474, 28382, 28381, 20220, 20218]"
    total 0
  end
  factory :product do
    title {|n| "Product#{n}"}
    product_type "camera_bestbuy"
  end
  factory :scraping_correction do
    association :scraping_rule
    product_type "camera_bestbuy"
    raw "error--"
    corrected "good to go"
    product_id "100000B" #SKU
  end
  factory :search do
     created_at {|d| "2011-11-#{d}"}
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
  factory :product_sibling do
    association :product
  end
  factory :product_bundle do
    association :product
  end
end