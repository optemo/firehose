class ResultsController < ApplicationController
  # GET /results
  # GET /results.xml
  def index
    @results = Result.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @results }
    end
  end

  # GET /results/1
  # GET /results/1.xml
  def show
    @result = Result.find(params[:id])
    
    @category_id = @result.category
    @product_count = @result.total
    @candidate_rules = Hash.new{|h,k| h[k] = Hash.new{|i,l| i[l] = Hash.new}}
    @delinquent_rules = Hash.new{|h,k| h[k] = Hash.new{|i,l| i[l] = Hash.new}}
    @result.candidates.map{|c|[c.scraping_rule.local_featurename, c.scraping_rule.remote_featurename, c.scraping_rule, c.product_id, c.parsed, c.raw, c.delinquent, c.scraping_correction_id]}.group_by{|c|c[0]}.each_pair do |local_featurename,c|
      c.group_by{|c|c[1]}.each_pair do |remote_featurename, c|
        c.group_by{|c|c[6]}.each_pair do |delinquent, c|
          if delinquent
            whichclass = @delinquent_rules
          else
            whichclass = @candidate_rules
          end
          whichclass[local_featurename][remote_featurename]["products"] = c.map{|cc|[cc[3],cc[4],cc[5],(cc[7].nil? ? nil : ScrapingCorrection.find(cc[7]))]}
          whichclass[local_featurename][remote_featurename]["rule"] = c.first[2]
        end
      end
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @result }
    end
  end

  # GET /results/new
  # GET /results/new.xml
  def new
    @result = Result.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @result }
    end
  end

  # GET /results/1/edit
  def edit
    @result = Result.find(params[:id])
  end

  # POST /results
  # POST /results.xml
  def create
    @result = Result.new(params[:result])
    @result.scraping_rules = ScrapingRule.find_all_by_product_type_and_active(Session.product_type, true).uniq # There are multiples in the table for some reason...
    
    product_skus = BestBuyApi.category_ids(@result.category)
    @result.total = product_skus.count
    @result.save
    errors = 0
    warnings = 0
    active_rules = ScrapingRule.find_all_by_active(true)
    # Make sure each rule knows which results it is part of
    active_rules.each {|r| r.results.push(@result); r.save}
    product_skus.each do |sku|
      res = ScrapingRule.scrape(sku)
      res.each_pair do |local_feature, i|
        i.each_pair do |remote_feature, ii|
          parsed = ii["products"].first[1]
          raw = ii["products"].first[2]
          corr = ii["products"].first[3]
          corr = corr.id if corr
          if (parsed.blank? && !raw.blank?) || (parsed == "**LOW") || (parsed == "**HIGH") || (parsed == "**Regex Error")#This is a missing value
            errors += 1
            delinquent = true
          else
            delinquent = false
          end
          Candidate.create(:parsed => parsed, :raw => raw, :scraping_rule_id => ii["rule"].id, :product_id => sku, :result_id => @result.id, :delinquent => delinquent, :scraping_correction_id => corr)
        end
      end
    end
    @result.update_attribute(:error_count, errors)
    
    
    respond_to do |format|
      if @result.save
        format.html { redirect_to(@result, :notice => 'Result was successfully created.') }
        format.xml  { render :xml => @result, :status => :created, :location => @result }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @result.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /results/1
  # PUT /results/1.xml
  def update
    @result = Result.find(params[:id])

    respond_to do |format|
      if @result.update_attributes(params[:result])
        format.html { redirect_to(@result, :notice => 'Result was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @result.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /results/1
  # DELETE /results/1.xml
  def destroy
    @result = Result.find(params[:id])
    @result.destroy

    respond_to do |format|
      format.html { redirect_to(results_url) }
      format.xml  { head :ok }
    end
  end
  
  # POST /results/commit/1
  # POST /results/commit/1.xml
  def commit
    @result = Result.find(params[:id])
    Product.create_from_result(@result.id)
  end
end
