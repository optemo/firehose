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
    @rules = Hash.new{|h,k| h[k] = Hash.new{|i,l| i[l] = ScrapedResult.new}} #Each of the rules that will be displayed
    @products = Hash.new{|h,k| h[k] = Hash.new} #Which rule was used for a product when multiple rules are available
    @colors = Hash.new #A specific color for each rule
    @result.candidates.map{|c|[c.scraping_rule.local_featurename, c.scraping_rule.remote_featurename, c.scraping_rule, c.product_id, c.parsed, c.raw, c.delinquent, c.scraping_correction_id]}.group_by{|c|c[0]}.each_pair do |local_featurename,c|
      c.sort{|a,b|(b[6] ? 2 : b[7] ? 1 : 0) <=> (a[6] ? 2 : a[7] ? 1 : 0)}.each do |c|
        @rules[local_featurename][c[2].id].add(c[2],ScrapedProduct.new(:id => c[3], :parsed => c[4], :raw => c[5], :delinquent => c[6], :corrected => (c[7].nil? ? nil : ScrapingCorrection.find(c[7]))))
        
        @products[local_featurename][c[3]] = ScrapedProduct.new(:id => c[3], :parsed => c[4], :rule => c[2], :delinquent => c[6], :scraping_correction_id => c[7]) unless @products[local_featurename][c[3]] && (c[6] || ( !@products[local_featurename][c[3]].delinquent && @products[local_featurename][c[3]].rule.priority < c[2].priority))
      end
    end
    #Only show combined products if there's more than one rule
    @rules.each do |local_featurename, rule_id|
      if rule_id.keys.count <= 1
        @products[local_featurename] = nil
      else
        @products[local_featurename] = @products[local_featurename].values.sort{|a,b|(b.delinquent ? 2 : b.scraping_correction_id ? 1 : 0) <=> (a.delinquent ? 2 : a.scraping_correction_id ? 1 : 0)}
      end
      @colors[local_featurename] = Hash[*rule_id.keys.zip(%w(#4F3333 green blue purple pink yellow orange brown black)).flatten]
    end
    @rules.each do |lf,rules|
      @rules[lf] = rules.values.sort{|a,b|a.rule.priority <=> b.rule.priority}
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
    candidate_records = []
    product_skus.each do |sku|
      ScrapingRule.scrape(sku).each_pair do |local_feature, i|
        # Now sorted, we want to take a rule that actually applies. To do this, run through them in priority order until one works.
        i.each do |sr|
          parsed = sr.products.first.parsed
          raw = sr.products.first.raw
          corr = sr.products.first.corrected
          corr = corr.id if corr
          if (!corr && (parsed.blank? && !raw.blank?) || (parsed == "**LOW") || (parsed == "**HIGH") || (parsed == "**Regex Error"))#This is a missing value
            errors += 1
            delinquent = true
          else
            delinquent = false
          end          
          candidate_records.push(Candidate.new({:parsed => parsed, :raw => raw, :scraping_rule_id => sr.rule.id, :product_id => sku, :result_id => @result.id, :delinquent => delinquent, :scraping_correction_id => corr}))
        end
      end
    end
    Candidate.transaction do
      candidate_records.each(&:save)
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
