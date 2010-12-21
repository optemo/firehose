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

ActiveRecord::Schema.define(:version => 20101220233958) do

  create_table "bin_specs", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.boolean  "value"
    t.string   "product_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bin_specs", ["product_id"], :name => "index_bin_specs_on_product_id"

  create_table "candidates", :force => true do |t|
    t.integer  "scraping_rule_id"
    t.integer  "result_id"
    t.integer  "product_id"
    t.string   "parsed"
    t.string   "raw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delinquent",       :default => false
  end

  create_table "cat_specs", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.string   "value"
    t.string   "product_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cat_specs", ["product_id"], :name => "index_cat_specs_on_product_id"

  create_table "cont_specs", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.float    "value"
    t.string   "product_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cont_specs", ["product_id"], :name => "index_cont_specs_on_product_id"

  create_table "delinquents", :force => true do |t|
    t.integer  "scraping_rule_id"
    t.integer  "result_id"
    t.integer  "product_id"
    t.string   "parsed"
    t.string   "raw"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", :force => true do |t|
    t.string   "sku"
    t.string   "product_type"
    t.string   "title"
    t.string   "model"
    t.string   "mpn"
    t.boolean  "instock"
    t.string   "imgsurl"
    t.string   "imgmurl"
    t.string   "imglurl"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "results", :force => true do |t|
    t.integer  "total"
    t.integer  "error_count"
    t.integer  "warning_count"
    t.string   "product_type"
    t.string   "category"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "results_scraping_rules", :id => false, :force => true do |t|
    t.integer "result_id"
    t.integer "scraping_rule_id"
  end

  create_table "scraping_corrections", :force => true do |t|
    t.string   "product_id"
    t.string   "product_type"
    t.string   "raw"
    t.string   "corrected"
    t.string   "remote_featurename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "scraping_corrections", ["product_id"], :name => "index_scraping_corrections_on_product_id"
  add_index "scraping_corrections", ["product_type"], :name => "index_scraping_corrections_on_product_type"

  create_table "scraping_rules", :force => true do |t|
    t.string  "local_featurename"
    t.string  "remote_featurename"
    t.text    "regex"
    t.string  "product_type"
    t.float   "min"
    t.float   "max"
    t.text    "valid_inputs"
    t.string  "rule_type"
    t.boolean "active",             :default => true
  end

end
