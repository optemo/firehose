class ScrapingRule < ActiveRecord::Base
  #Validation for remote_featurename, local_featurename
  validates :local_featurename,  :presence => true
  validates :remote_featurename, :presence => true
  validates :regex, :presence => true
  validates :product_type, :presence => true
  validates :rule_type, :presence => true
  has_many :candidates
  has_and_belongs_to_many :results
  
  def self.scrape(ids, inc_raw = false) #Can accept both one or more ids
    #Return type: [local_featurename][remote_featurename]["products"] = [product_id,parsed,raw]
    #             [local_featurename][remote_featurename]["rule"] = ScrapingRule
    #Three layer return type
    data = Hash.new{|h,k| h[k] = Hash.new{|i,l| i[l] = Hash.new{|j,m| j[m] = []}}}
    ids = [ids] unless ids.kind_of? Array
    ids.each do |id|
      sleep 0.5 if defined? looped
      raw_info = BestBuyApi.product_search(id)
      unless raw_info.nil?
        corrections = ScrapingCorrection.find_all_by_product_id_and_product_type(id,Session.product_type)
        rules = ScrapingRule.find_all_by_product_type_and_active(Session.product_type, true)
        rules.each do |r|
          #Find content based on . seperated hierarchical description
          identifiers = r.remote_featurename.split(".")
          raw = raw_info
          #Traverse the hash hierarchy
          identifiers.each {|i| raw = raw[i] unless raw.nil?}
          raw = "" unless raw
          corr = corrections.select{|c|c.remote_featurename == r.remote_featurename && c.raw == raw.to_s}.first
          if corr
            parsed = corr.corrected
          else
            regexstr = r.regex.gsub(/^\//,"").gsub(/([^\\])\/$/,'\1')
            replace_i = regexstr.index(/[^\\]\//)
            begin
              if replace_i
                #Replacement part of the regex
                parsed = raw.gsub(Regexp.new(regexstr[0..replace_i]),regexstr[replace_i+2..-1])
              else
                #Just match, not replacement
                parsed = Regexp.new(regexstr).match(raw.to_s)
              end
              #Test for min / max
              parsed = "**LOW" if r.min && parsed && parsed.to_s.to_f < r.min
              parsed = "**HIGH" if r.max && parsed && parsed.to_s.to_f > r.max
              
            rescue RegexpError
              parsed = "**Regex Error"
            end
          end
          #Save the cleaned result
          data[r.local_featurename][r.remote_featurename]["products"] << [id,parsed.to_s,raw.to_s,corr]
          data[r.local_featurename][r.remote_featurename]["rule"] = r
        end
        #Include raw json for other functionality
        data["RAW-JSON"] = raw_info if inc_raw
      end
      looped = true
    end
    data
  end
end