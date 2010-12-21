class ScrapingRulesController < ApplicationController
  layout false
  def new
    @scraping_rule = ScrapingRule.new
    @remote_rule_pair = {}
    if params[:rule]
      @remote_rule_pair = params[:rule].split("--").map(&:strip)
    end
    render :layout => false
  end
  
  def edit
    @scraping_rule = ScrapingRule.find(params[:id])
  end

  def create
    # Creates a new scraping rule.
    # There are four kinds of rules: continuous, binary, categorical, and intrinsic.
    # The first three kinds end up being specs bound to the product, e.g. ContSpec, 
    # while the last kind of rule inserts values directly into the product row.
    @scraping_rule = ScrapingRule.new(params[:rule])
    @scraping_rule.product_type = Session.product_type
    if @scraping_rule.valid?
      @scraping_rule.save
    else
      # error
    end
  end
  
  def update
    if(Candidate.find_by_scraping_rule_id(params[:id]))
      #We have found a dependancy on the rule
      old_scrape = ScrapingRule.find(params[:id])
      atts = old_scrape.attributes.merge(params[:scraping_rule])
      atts.delete(:id)
      succeeded = ScrapingRule.create(atts)
      old_scrape.update_attribute("active",false) if succeeded
    else
      succeeded = ScrapingRule.find(params[:id]).update_attributes(params[:scraping_rule])
    end
    
    respond_to do |format|
      if succeeded
        format.html { head :ok }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  def destroy
    if(Candidate.find_by_scraping_rule_id(params[:id]))
      #We have found a dependancy on the rule, so we'll just make it inactive
      ScrapingRule.find(params[:id]).update_attribute("active",false)
    else
      ScrapingRule.find(params[:id]).destroy
    end
    
    respond_to do |format|
      format.html { head :ok }
      format.xml  { head :ok }
    end
  end
end
