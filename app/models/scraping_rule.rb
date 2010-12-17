class ScrapingRule < ActiveRecord::Base
  #Validation for remote_featurename, local_featurename
  
  def self.scrape(ids, inc_raw = false) #Can accept both one or more ids
    #Return type: [local_featurename][remote_featurename][product_id] = [parsed,raw,rule]
    #Three layer return type
    data = Hash.new{|h,k| h[k] = Hash.new{|i,l| i[l] = Hash.new}}
    ids = [ids] unless ids.kind_of? Array
    ids.each do |id|
      sleep 0.5 if defined? looped
      raw_info = BestBuyApi.product_search(id)
      unless raw_info.nil?
        rules = ScrapingRule.find_all_by_product_type(Session.product_type)
        rules.each do |r|
          #Find content based on . seperated hierarchical description
          identifiers = r.remote_featurename.split(".")
          raw = raw_info
          #Traverse the hash hierarchy
          identifiers.each {|i| raw = raw[i] unless raw.nil?}
          if raw
            regex = Regexp.new(r.regex)
            parsed = regex.match(raw.to_s)
            #Save the cleaned result
            data[r.local_featurename][r.remote_featurename][id] = [parsed.to_s,raw.to_s,r] if parsed
          end
        end
        #Include raw json for other functionality
        data["RAW-JSON"] = raw_info if inc_raw
      end
      looped = true
    end
    data
  end
end