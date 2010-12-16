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
    # There are three kinds of rules, continuous, binary, and categorical.
    @scraping_rule = ScrapingRule.new(params[:rule])
    @scraping_rule.product_type = Session.product_type
    if @scraping_rule.valid?
      @scraping_rule.save
    else
      # error
    end
  end
  
  def update
    
  end
  
  def delete
    
  end
end
