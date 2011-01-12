#Here is where general upkeep scripts are
desc "Calculate factors for all features of all products, and pre-calculate utility scores"
task :calculate_factors => :environment do
  # Do not truncate Factor table anymore. Instead, add more factors for the given URL.
  file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
  unless ENV.include?("url") && (s = Session.new(ENV["url"])) && file[ENV["url"]]
    raise "usage: rake calculate_factors url=? # url is a valid url from products.yml; sets product_type."
  end
  
  cont_activerecords = []
  #cat_activerecords =[]
  #bin_activerecords = []
  cont_spec_local_cache = {} # This saves doing many ContSpec lookups. It's a hash with {id => value} pairs
  all_products = Product.valid.instock
  all_products.each do |product|
    utility = []
    s.continuous["filter"].each do |f|
      unless cont_spec_local_cache[f]
        records = ContSpec.find(:all, :select => 'product_id, value', :conditions => ["product_id IN (?) and name = ?", all_products, f])
        temp_hash = {}
        records.each do |r| # Strip the records down to {id => value} pairs
          temp_hash[r.product_id] = r.value
        end
        cont_spec_local_cache[f] = temp_hash
      end
      newFactorRow = ContSpec.new({:product_id => product.id, :product_type => s.product_type, :name => f+"_factor"})
      fVal = cont_spec_local_cache[f][product.id]
      debugger unless fVal # The alternative here is to crash. This should never happen if Product.valid.instock is doing its job.
      newFactorRow.value = calculateFactor(fVal, f, cont_spec_local_cache[f])
      utility << newFactorRow.value
      cont_activerecords.push(newFactorRow)
    end
    #Add the static calculated utility
    cont_activerecords.push ContSpec.new({:product_id => product.id, :product_type => s.product_type, :name => "utility", :value => utility.sum})
  end
  
  ContSpec.delete_all(["name = 'utility' and product_type = ?", s.product_type])
  s.continuous["filter"].each{|f| ContSpec.delete_all(["name = ? and product_type = ?", f+"_factor", s.product_type])} # ContSpec records do not have a version number, so we have to wipe out the old ones.  
  # Do all record saving at the end for efficiency
  ContSpec.transaction do
    cont_activerecords.each(&:save)
  end
end

def calculateFactor(fVal, f, contspecs)
  # Order the feature values, reversed to give the highest value to duplicates
  ordered = contspecs.values.sort
  ordered = ordered.reverse if Session.current.prefDirection[f] == 1
  return 0 if Session.current.prefDirection[f] == 0
  pos = ordered.index(fVal)
  len = ordered.length
  (len - pos)/len.to_f
end