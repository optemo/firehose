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
    
    Session.category_id = @result.category
    @product_count = @result.total
    @rules = Hash.new{|h,k| h[k] = Hash.new{|i,l| i[l] = ScrapedResult.new}}
    @result.candidates.map{|c|[c.scraping_rule.local_featurename, c.scraping_rule.remote_featurename, c.scraping_rule, c.product_id, c.parsed, c.raw, c.delinquent, c.scraping_correction_id]}.group_by{|c|c[0]}.each_pair do |local_featurename,c|
      c.each{|c|@rules[local_featurename][c[2].id].add(c[2],ScrapedProduct.new(:id => c[3], :parsed => c[4], :raw => c[5], :corrected => (c[7].nil? ? nil : ScrapingCorrection.find(c[7]))))}
    end
    @rules.each do |lf,rules|
      @rules[lf] = rules.values.sort{|a,b|a.rule.priority <=> b.rule.priority}
    end
    @rules.each do |n,r| # n is the rule name, r is a hash with remote_featurename => {products => ..., rule => ...}
      # For each local feature, we want to build up a list of products that are touched by one or more rules.
      # This becomes the overall coverage, with the 
      # One easy way to do this is with a hash whose keys are the skus.
      sku_hash = {}
      r.each do |scraped_result|
        scraped_result.products.each{|p|sku_hash[p.id] = 1 unless p.parsed.blank?}
      end
      # Put the coverage in a variable that we can get out in the view.
      @rules[n].unshift sku_hash.keys.length
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @result }
    end
  end

  # GET /results/new
  # GET /results/new.xml
  def new
    @result = Result.new(:product_type => Session.current.product_type)

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
    @result.scraping_rules = ScrapingRule.find_all_by_product_type_and_active(Session.current.product_type, true).uniq # There are multiples in the table for some reason...
    
    product_skus = BestBuyApi.category_ids(@result.category)
    @result.total = product_skus.count
    @result.save
    errors = 0
    warnings = 0
    active_rules = ScrapingRule.find_all_by_active(true)
    # Make sure each rule knows which results it is part of
    active_rules.each {|r| r.results.push(@result); r.save}
    product_skus.each do |sku|
      ScrapingRule.scrape(sku).each_pair do |local_feature, i|
        # Now sorted, we want to take a rule that actually applies. To do this, run through them in priority order until one works.
        i.each_pair do |lf, data|
          parsed = data.products.first.first.parsed
          raw = data.products.first.first.raw
          corr = data.products.first.first.corrected
          corr = corr.id if corr
          if (!corr && (parsed.blank? && !raw.blank?) || (parsed == "**LOW") || (parsed == "**HIGH") || (parsed == "**Regex Error"))#This is a missing value
            errors += 1
            delinquent = true
          else
            delinquent = false
          end          
          Candidate.create(:parsed => parsed, :raw => raw, :scraping_rule_id => data.rules.first.id, :product_id => sku, :result_id => @result.id, :delinquent => delinquent, :scraping_correction_id => corr)
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
    
    myscraping_rules = @result.scraping_rules
    #Remove any associated candidates
    @result.candidates.each(&:destroy)
    #Remove any unneeded scraping rules
    myscraping_rules.each do |sr|
      next if sr.active
      next unless Candidate.find_by_scraping_rule_id(sr.id).nil?
      sr.destroy
    end
    #Destroy the results
    @result.destroy

    respond_to do |format|
      format.html { head :ok }
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
