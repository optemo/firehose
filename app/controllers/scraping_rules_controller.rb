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
    @scraping_rule = ScrapingRule.find(params[:id])

    respond_to do |format|
      if @scraping_rule.update_attributes(params[:scraping_rule])
        format.html { render :nothing => true }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @scraping_rule.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def delete
    
  end
end
