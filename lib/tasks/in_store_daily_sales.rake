task :save_instore_sales => :environment do
  Session.new
  require 'save_instore_daily_sales'
  save_instore_daily_sales()
end

#***********Choose task to carry through***********#
task :analyze_bestbuy_data => :environment do
  require 'bestbuy_data_analysis'
  #bb_multiple_same_items_same_purchase()
  #diff_store_ids()
  #find_zeroes()
  #unique_purchase_ids()
  #count_lines()
  #find_out_of_month_sales()
  find_sku_length(7)
end

task :compare_onlinesales_to_bestbuy_file => :environment do
  require 'dbOnline_vs_bbuyOnline'
  
  check_db_online_sales_match_bbuy_file()
end