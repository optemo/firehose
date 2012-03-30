class ScrapingRulesController < ApplicationController
  layout false, except: :index
  
  def index
    @rules = ScrapingRule.order('priority').find_all_by_product_type(Session.product_type).group_by(&:local_featurename)
    @colors = {}
    @rules.each_pair do |lf, rs|
      @colors.merge! Hash[*rs.map(&:id).zip(%w(#4F3333 green blue purple pink yellow orange brown black)).flatten]
    end
    #Calculate Coverage
    
    if params[:coverage] || params[:full]
      @coverage = {}
      products = params[:full] ? BestBuyApi.category_ids(Session.product_type) : BestBuyApi.some_ids(Session.product_type)
      @products_count = products.count
      ScrapingRule.scrape(products).group_by{|c|c.scraping_rule.local_featurename}.each_pair do |lf, candidates| 
        groups = candidates.group_by(&:scraping_rule_id)
        if groups.keys.length > 1
          @coverage[lf] = covered(Candidate.multi(candidates))
        end
        groups.each_pair{|sr_id, candidates| @coverage[sr_id] = covered(candidates)}
      end
    end
  end
  
  def new
    @raw = params[:raw]
    #Fix utf-8 encoding
    params[:rule][:remote_featurename] = CGI::unescape(params[:rule][:remote_featurename]) if params[:rule] && params[:rule][:remote_featurename] 
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
    if ScrapingRule.find_all_by_product_type_and_local_featurename(ProductCategory.get_ancestors(Session.product_type), @scraping_rule.local_featurename).empty?
      @scraping_rule.product_type = Session.product_type
      # For priority, find all the scraping rules that share that local featurename (for that product type)
      potential_previous_scraping_rules = ScrapingRule.find_all_by_local_featurename_and_product_type(@scraping_rule.local_featurename, Session.product_type)
      # If there are any, get the highest priority and increment it for the new rule.
      # This gives all new rules a lower priority (lower priority number means higher priority).
      unless potential_previous_scraping_rules.empty?
        @scraping_rule.priority = (potential_previous_scraping_rules.map(&:priority).max + 1)
      end
      respond_to do |format|
        if @scraping_rule.save
          format.html { render text: "[REDIRECT]#{ product_type_scraping_rules_url(Session.product_type) }" }
        else
          format.html { head :bad_request }
        end
      end
    else
      # error
      respond_to do |format|
        format.html { head :bad_request }
      end
    end
  end
  
  def update
    succeeded = ScrapingRule.find(params[:id]).update_attributes(params[:scraping_rule].reject{|k,v|v.blank?})
    
    respond_to do |format|
      if succeeded
        format.html { render text: "[REDIRECT]#{ product_type_scraping_rules_url(Session.product_type) }" }
      else
        format.html { head :bad_request }
      end
    end
  end
  
  def show
    if request.referer =~ /full/
      #Results, so get all products
      products = Session.product_type_leaves.inject([]) do |res, leaf|
        res + BestBuyApi.category_ids(leaf)
      end
    else
      #Rules, so only show a few 
      leaves = Session.product_type_leaves
      products = leaves[0..9].inject([]) do |res, leaf|
        res + BestBuyApi.some_ids(leaf,[10/leaves.size,1].max)
      end
    end
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
    render :partial => 'candidate', :collection => @candidates
  end
  
  def destroy
    ScrapingCorrection.delete_all(["scraping_rule_id = ?",params[:id]])
    ScrapingRule.find(params[:id]).destroy
    render :nothing => true
  end
  
  private
  def covered(array)
    #Used to calculate feed coverage
    array.inject(0){|res,elem|elem.delinquent ? res : res+1}
  end
end
