class ScrapingController < ApplicationController
  def index
  end
  
  def datafeed
    # This function shows the application frame and shows a list of the products for a given category.
    if params[:category_id]
      Session.category_id = params[:category_id]
    end
    @product_skus = BestBuyApi.category_ids(Session.category_id)
  end

  def scrape
    require 'ruby-debug' #Used for pretty print PP
    ids = params[:id].split(',') # the patten of params[:id] is product_id,category_id
    @id = ids[0]
    candidates, @raw_info = ScrapingRule.scrape(BBproduct.new(:id => @id, :category => ids[1]),true)
    @scraped_features = Candidate.organize(candidates).first
    render :layout => false
  end
  
  def rules
    products,@exists_count = BestBuyApi.some_ids(Session.category_id)
    @product_count = products.count
    @rules, @multirules, @colors = Candidate.organize(ScrapingRule.scrape(products))

    if (newcount = @rules.values.first.first.count) < @product_count
      @warning = "#{@product_count-newcount} product#{'s' if @product_count-newcount > 1} missing"
      @product_count = newcount
    end
  end
  
  def myrules
    @rules = ScrapingRule.order('priority').find_all_by_product_type(Session.product_type).group_by(&:local_featurename)
    @colors = {}
    @rules.each_pair do |lf, rs|
      @colors.merge! Hash[*rs.map(&:id).zip(%w(#4F3333 green blue purple pink yellow orange brown black)).flatten]
    end
    #Calculate Coverage
    
    if params[:coverage]
      @coverage = {}
      products,@exists_count = BestBuyApi.some_ids(Session.category_id)
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
  
  private
  def covered(array)
    #Used to calculate feed coverage
    array.inject(0){|res,elem|elem.delinquent ? res : res+1}
  end
end
