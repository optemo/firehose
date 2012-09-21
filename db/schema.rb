# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120912175305) do

  create_table "accessories", :force => true do |t|
    t.integer  "product_id"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "value"
    t.string   "acc_type"
  end

  create_table "bin_specs", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.boolean  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "modified"
  end

  add_index "bin_specs", ["name"], :name => "index_bin_specs_on_name"
  add_index "bin_specs", ["product_id"], :name => "index_bin_specs_on_product_id"

  create_table "cat_specs", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "modified"
  end

  add_index "cat_specs", ["name"], :name => "index_cat_specs_on_name"
  add_index "cat_specs", ["product_id"], :name => "index_cat_specs_on_product_id"

  create_table "cont_specs", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.float    "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "modified"
  end

  add_index "cont_specs", ["name", "product_id"], :name => "index_cont_specs_on_name_and_product_id"
  add_index "cont_specs", ["product_id"], :name => "index_cont_specs_on_product_id"
  add_index "cont_specs", ["value"], :name => "index_cont_specs_on_value"

  create_table "daily_specs", :force => true do |t|
    t.string   "sku"
    t.string   "name"
    t.string   "spec_type"
    t.string   "value_txt"
    t.float    "value_flt"
    t.boolean  "value_bin"
    t.string   "product_type"
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "daily_specs", ["sku", "name", "product_type", "date"], :name => "sku", :unique => true

  create_table "dynamic_facets", :force => true do |t|
    t.integer "facet_id", :null => false
    t.string  "category", :null => false
  end

  add_index "dynamic_facets", ["facet_id", "category"], :name => "index_dynamic_facets_on_facet_id_and_category", :unique => true

  create_table "equivalences", :force => true do |t|
    t.integer "product_id"
    t.string  "eq_id"
  end

  add_index "equivalences", ["eq_id"], :name => "index_equivalences_on_eq_id"
  add_index "equivalences", ["product_id"], :name => "index_equivalences_on_product_id"

  create_table "facets", :force => true do |t|
    t.string  "name",                                    :null => false
    t.string  "feature_type", :default => "Categorical", :null => false
    t.string  "used_for",     :default => "show"
    t.float   "value"
    t.string  "style",        :default => ""
    t.boolean "active",       :default => true
    t.string  "product_type"
    t.string  "ui"
  end

  add_index "facets", ["used_for"], :name => "index_facets_on_used_for"

  create_table "product_bundles", :force => true do |t|
    t.integer  "bundle_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "product_bundles", ["bundle_id"], :name => "index_product_bundles_on_bundle_id", :unique => true

  create_table "product_categories", :force => true do |t|
    t.string  "product_type"
    t.string  "feed_id"
    t.string  "retailer"
    t.integer "l_id"
    t.integer "r_id"
    t.integer "level"
  end

  create_table "product_siblings", :force => true do |t|
    t.integer  "product_id"
    t.integer  "sibling_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "product_siblings", ["product_id"], :name => "index_product_siblings_on_product_id"

  create_table "products", :force => true do |t|
    t.string  "sku"
    t.boolean "instock"
    t.string  "retailer"
  end

  create_table "scraping_corrections", :force => true do |t|
    t.string   "product_id"
    t.string   "raw"
    t.text     "corrected"
    t.integer  "scraping_rule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "scraping_corrections", ["product_id"], :name => "index_scraping_corrections_on_product_id"

  create_table "scraping_rules", :force => true do |t|
    t.string  "local_featurename"
    t.string  "remote_featurename"
    t.text    "regex"
    t.string  "product_type"
    t.float   "min"
    t.float   "max"
    t.text    "valid_inputs"
    t.string  "rule_type"
    t.integer "priority",           :default => 0
    t.boolean "french",             :default => false
    t.boolean "bilingual",          :default => false
  end

  create_table "searches", :force => true do |t|
    t.integer  "parent_id"
    t.boolean  "initial"
    t.string   "keyword_search"
    t.integer  "page"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sortby"
    t.string   "product_type"
    t.string   "params_hash"
  end

  add_index "searches", ["params_hash"], :name => "index_searches_on_params_hash"

  create_table "surveys", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "session_id"
    t.string   "firstname"
    t.string   "lastname"
    t.string   "rating"
    t.boolean  "followup"
    t.string   "email"
    t.text     "experience"
    t.text     "improvements"
  end

  create_table "text_specs", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "modified"
  end

  add_index "text_specs", ["product_id", "name"], :name => "index_text_specs_on_product_id_and_name"

  create_table "translations", :force => true do |t|
    t.string   "locale"
    t.string   "key"
    t.text     "value"
    t.text     "interpolations"
    t.boolean  "is_proc",        :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "userdatabins", :force => true do |t|
    t.integer  "search_id"
    t.string   "name"
    t.boolean  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "userdatabins", ["search_id"], :name => "index_userdatabins_on_search_id"

  create_table "userdatacats", :force => true do |t|
    t.integer  "search_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "userdatacats", ["search_id"], :name => "index_userdatacats_on_search_id"

  create_table "userdataconts", :force => true do |t|
    t.integer  "search_id"
    t.string   "name"
    t.float    "min"
    t.float    "max"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "userdataconts", ["search_id"], :name => "index_userdataconts_on_search_id"

end
