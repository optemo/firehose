Factory.define :candidate do |f|
  f.association :scraping_rule
  f.association :result
  f.association :scraping_correction
  f.product_id "100000A" #SKU
  f.parsed "value"
  f.raw "rawvalue"
end

Factory.define :scraping_rule do |f|
  f.local_featurename "title"
  f.remote_featurename "title"
  f.product_type "camera_bestbuy"
  f.rule_type "Categorical"
  f.regex ".*"
end

Factory.define :result do |f|
  f.product_type "camera_bestbuy"
  f.category "--[22474, 28382, 28381, 20220, 20218]"
  f.total 0
end

Factory.define :product do |f|
  f.title {|n| "Product#{n}"}
end

Factory.define :scraping_correction do |f|
  f.association :scraping_rule
  f.product_type "camera_bestbuy"
  f.raw "error--"
  f.corrected "good to go"
  f.product_id "100000B" #SKU
end