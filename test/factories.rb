FactoryGirl.define do
  factory :candidate do
    association :scraping_rule
    association :scraping_correction
    sku "100000A"
    parsed "value"
    raw "rawvalue"
  end
  factory :scraping_rule do
    sequence(:local_featurename) {|n| "title#{n}"}
    remote_featurename "title"
    product_type "B20218"
    sequence(:rule_type) {|n|
      case n % 3
      when 0
        "Continuous"
      when 1
        "Categorical"
      when 2
        "Binary"
      end}
    regex ".*"
  end
  
  factory :facet do
    product_type "B20218"
    sequence(:name) {|n| "facet#{n}"}
    sequence(:feature_type) {|n|
      case n % 3
      when 0
        "Continuous"
      when 1
        "Binary"
      when 2
        "Categorical"
      end}
    sequence(:used_for) {|n|
        case n % 3
        when 0
          "filter"
        when 1
          "show"
        when 2
          "sortby"
        end}
    sequence(:value) {|n| n}
    style ""
    active 1
  end
  
  factory :result do
    product_type "camera_bestbuy"
    category "--[22474, 28382, 28381, 20220, 20218]"
    total 0
  end
  factory :product do
    instock true
  end
  factory :product_type do
    name {|n| "test_type#{n}"}
  end
  factory :category_id_product_type_map do
    association :product_type
  end
  factory :scraping_correction do
    #association :scraping_rule
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
  factory :product_category
end