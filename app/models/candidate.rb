class Candidate
  include ActiveModel::Serialization
  attr_accessor :scraping_rule_id
  attr_accessor :scraping_correction_id
  attr_accessor :model
  attr_accessor :name
  attr_accessor :sku
  attr_accessor :parsed
  attr_accessor :raw
  attr_accessor :delinquent
  attr_writer :scraping_correction
  attr_writer :scraping_rule
  
  def scraping_correction
    @scraping_correction ||= ScrapingCorrection.find(@scraping_correction_id) if @scraping_correction_id
    @scraping_correction
  end
  
  def scraping_rule
    @scraping_rule ||= ScrapingRule.find(@scraping_rule_id) if @scraping_rule_id
    @scraping_rule
  end
  
  def initialize(params={})
    @scraping_rule_id = params[:scraping_rule_id]
    @scraping_correction_id = params[:scraping_correction_id]
    @model = params[:model]
    @name = params[:name]
    @sku = params[:sku]
    @parsed = params[:parsed]
    @raw = params[:raw]
    @delinquent = params[:delinquent]
  end
  
  def self.organize(candidates)
    rules = Hash.new{|h,k| h[k] = Hash.new} #Each of the rules that will be displayed
    multirules = Hash.new{|h,k| h[k] = Hash.new} #Which rule was used for a product when multiple rules are available
    colors = Hash.new #A specific color for each rule
    candidates.group_by{|c|c.scraping_rule.local_featurename}.each_pair do |local_featurename,c| 
      c.group_by{|c|c.scraping_rule.id}.each_pair do |scraping_rule_id,c|
        #Sort the products so that delinquents and corrected products show up first
        rules[local_featurename][scraping_rule_id] = c.sort{|a,b|(b.delinquent ? 2 : b.scraping_correction_id ? 1 : 0) <=> (a.delinquent ? 2 : a.scraping_correction_id ? 1 : 0)}
        c.each do |c|
          multirules[local_featurename][c.sku] = c unless multirules[local_featurename][c.sku] && (c.delinquent || (!multirules[local_featurename][c.sku].delinquent && multirules[local_featurename][c.sku].scraping_rule.priority < c.scraping_rule.priority))
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
  
  def self.multi(candidates,sort = true)
    res = {}
    #Assign candidates by scraping rule priority
    candidates.each do |c|
      res[c.sku] = c unless res[c.sku] && (c.delinquent || (!res[c.sku].delinquent && res[c.sku].scraping_rule.priority < c.scraping_rule.priority))
    end
    #Order candidates by delinquents & corrections
    if sort
      res.values.sort{|a,b|(b.delinquent ? 2 : b.scraping_correction_id ? 1 : 0) <=> (a.delinquent ? 2 : a.scraping_correction_id ? 1 : 0)}
    else
      res.values
    end
  end
end
