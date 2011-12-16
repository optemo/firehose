class ScrapingRulesController < ApplicationController
  layout false
  def new
    @raw = params[:raw]
    #Fix utf-8 encoding
    params[:rule][:remote_featurename] = CGI::unescape(params[:rule][:remote_featurename]) if params[:rule][:remote_featurename]
    @scraping_rule = ScrapingRule.new(params[:rule])
  end
  
  def edit
    @scraping_rule = ScrapingRule.find(params[:id])
  end

  def raisepriority
    # The basic algorithm is this: Find the given rule. Swap priorities with the rule that's one lower.
    rule = ScrapingRule.find(params[:id])
    if rule.priority > 0 # If the rule priority number is 0, its priority can't be raised higher
      other_rules = ScrapingRule.where("priority < ?", rule.priority).find_all_by_local_featurename_and_active(rule.local_featurename, 1)
      other_rule = other_rules.max{|a, b| a.priority <=> b.priority}
      if other_rule
        # Swap the priorities. It's not possible to do arithmetic operations for this because there might be some deleted rules
        # that leave holes in a range of priorities. Though we could handle this on the scraping_rule DELETE, we shouldn't and don't.
        temp_priority = rule.priority
        rule.priority = other_rule.priority
        other_rule.priority = temp_priority
        rule.save
        other_rule.save
      else
        # There is no rule with a lower priority number. For cleanliness, let's make this rule the highest priority (lowest number).
        rule.priority = 0
        rule.save
      end
    end
    respond_to {|format| format.html { head :ok }}
  end

  def create
    # Creates a new scraping rule.
    # There are four kinds of rules: continuous, binary, categorical, and intrinsic.
    # The first three kinds end up being specs bound to the product, e.g. ContSpec, 
    # while the last kind of rule inserts values directly into the product row.
    @scraping_rule = ScrapingRule.new(params[:scraping_rule])
    @scraping_rule.product_type = Session.p_type
    # For priority, find all the scraping rules that share that local featurename (for that product type)
    potential_previous_scraping_rules = ScrapingRule.find_all_by_local_featurename_and_product_type(@scraping_rule.local_featurename, Session.p_type)
    # If there are any, get the highest priority and increment it for the new rule.
    # This gives all new rules a lower priority (lower priority number means higher priority).
    unless potential_previous_scraping_rules.empty?
      @scraping_rule.priority = (potential_previous_scraping_rules.map(&:priority).max + 1)
    end

    respond_to do |format|
      if @scraping_rule.save
        format.html { redirect_to root_url }
      else
        format.html { head 412 }
      end
    end
  end
  
  def update
    succeeded = ScrapingRule.find(params[:id]).update_attributes(params[:scraping_rule].reject{|k,v|v.blank?})
    
    respond_to do |format|
      if succeeded
        format.html { redirect_to root_url }
      else
        format.html { head 412 }
      end
    end
  end
  
  def show
    products = request.referer =~ /results/ ? BestBuyApi.category_ids(Session.category_id) : BestBuyApi.some_ids(Session.category_id)
    scraping_rules = Maybe(params[:id]).split('-')
    @colors = Hash[*scraping_rules.zip(%w(#4F3333 green blue purple pink yellow orange brown black)).flatten]
    if scraping_rules.length > 1
      #Check multirules
      candidates = scraping_rules.map{|sr| ScrapingRule.scrape(products,false,ScrapingRule.find(sr))}.flatten
      @candidates = Candidate.multi(candidates)
    else
      #Check single rules
      @candidates = ScrapingRule.scrape(products,false,ScrapingRule.find(params[:id])).sort{|a,b|(b.delinquent ? 2 : b.scraping_correction_id ? 1 : 0) <=> (a.delinquent ? 2 : a.scraping_correction_id ? 1 : 0)}
    end
  end
  
  def destroy
    ScrapingCorrection.delete_all(["scraping_rule_id = ?",params[:id]])
    ScrapingRule.find(params[:id]).destroy
    
    respond_to do |format|
      format.html { redirect_to root_url }
      format.xml  { head 412 }
    end
  end
end
