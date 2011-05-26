class Candidate < ActiveRecord::Base
  belongs_to :result
  belongs_to :scraping_rule
  belongs_to :scraping_correction
  
  # def self.organize(candidates)
  #   # sorted_candidates = candidates.sort do |a,b|
  #   #   if a.scraping_rule.local_featurename == b.scraping_rule.local_featurename
  #   #     a.scraping_rule_id <=> b.scraping_rule_id
  #   #   else
  #   #     a.scraping_rule.local_featurename <=> b.scraping_rule.local_featurename
  #   #   end
  #   # end
    
  #   rules = Hash.new{|h,k| h[k] = Hash.new} #Each of the rules that will be displayed
  #   multirules = Hash.new{|h,k| h[k] = Hash.new} #Which rule was used for a product when multiple rules are available
  #   colors = Hash.new #A specific color for each rule

  #   candidates.each do |c|
  #     if rules[c.scraping_rule.local_featurename][c.scraping_rule_id].nil?
  #       rules[c.scraping_rule.local_featurename][c.scraping_rule_id] = [c]
  #     else
  #       rules[c.scraping_rule.local_featurename][c.scraping_rule_id] << c
  #     end
  #     multirules[c.scraping_rule.local_featurename][c.product_id] = c unless multirules[c.scraping_rule.local_featurename][c.product_id] && (c.delinquent || (!multirules[c.scraping_rule.local_featurename][c.product_id].delinquent && multirules[c.scraping_rule.local_featurename][c.product_id].scraping_rule.priority < c.scraping_rule.priority))
  #   end

  #   rules.each do |local_featurename, rule_id|
  #     if rule_id.keys.count <= 1
  #       multirules[local_featurename] = nil
  #     else
  #       #Resort products as there are multiple rules here
  #       multirules[local_featurename] = multirules[local_featurename].values.sort{|a,b|(b.delinquent ? 2 : b.scraping_correction_id ? 1 : 0) <=> (a.delinquent ? 2 : a.scraping_correction_id ? 1 : 0)}
  #     end
  #     colors[local_featurename] = Hash[*rule_id.keys.zip(%w(#4F3333 green blue purple pink yellow orange brown black)).flatten]
  #     #Order rules by priority for display
  #     rules[local_featurename] = rule_id.values.sort{|a,b|a.first.scraping_rule.priority <=> b.first.scraping_rule.priority}#.group_by{|a| a.first.scraping_rule.remote_featurename}
  #   end
    

  #   [rules,multirules,colors]
  # end

    
  def self.organize(candidates)
    rules = Hash.new{|h,k| h[k] = Hash.new} #Each of the rules that will be displayed
    multirules = Hash.new{|h,k| h[k] = Hash.new} #Which rule was used for a product when multiple rules are available
    colors = Hash.new #A specific color for each rule
    candidates.group_by{|c|c.scraping_rule.local_featurename}.each_pair do |local_featurename,c| 
      c.group_by{|c|c.scraping_rule.id}.each_pair do |scraping_rule_id,c|
        #Sort the products so that delinquents and corrected products show up first
        rules[local_featurename][scraping_rule_id] = c.sort{|a,b|(b.delinquent ? 2 : b.scraping_correction_id ? 1 : 0) <=> (a.delinquent ? 2 : a.scraping_correction_id ? 1 : 0)}
        c.each do |c|
          multirules[local_featurename][c.product_id] = c unless multirules[local_featurename][c.product_id] && (c.delinquent || (!multirules[local_featurename][c.product_id].delinquent && multirules[local_featurename][c.product_id].scraping_rule.priority < c.scraping_rule.priority))
        end
      end
    end
    rules.each do |local_featurename, rule_id|
      if rule_id.keys.count <= 1
        multirules[local_featurename] = nil
      else
        #Resort products as there are multiple rules here
        multirules[local_featurename] = multirules[local_featurename].values.sort{|a,b|(b.delinquent ? 2 : b.scraping_correction_id ? 1 : 0) <=> (a.delinquent ? 2 : a.scraping_correction_id ? 1 : 0)}
      end
      colors[local_featurename] = Hash[*rule_id.keys.zip(%w(#4F3333 green blue purple pink yellow orange brown black)).flatten]
    end
    
    #Order rules by priority for display
    rules.each do |lf,rule_ids|
      rules[lf] = rule_ids.values.sort{|a,b|a.first.scraping_rule.priority <=> b.first.scraping_rule.priority}#.group_by{|a| a.first.scraping_rule.remote_featurename}
    end

    [rules,multirules,colors]
  end

end
