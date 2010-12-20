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
    @delinquent_rules = Hash.new{|h,k| h[k] = Hash.new{|i,l| i[l] = Hash.new}}
    @candidate_rules = Hash.new{|h,k| h[k] = Hash.new{|i,l| i[l] = Hash.new}}
    @result.candidates.map{|d|[d.scraping_rule.local_featurename, d.scraping_rule.remote_featurename, d.scraping_rule, d.product_id, d.parsed, d.raw]}.group_by{|d|d[0]}.each_pair do |local_featurename,d|
      d.group_by{|d|d[1]}.each_pair do |remote_featurename, d|
        @candidate_rules[local_featurename][remote_featurename]["products"] = d.map{|dd|[dd[3],dd[4],dd[5]]}
        @candidate_rules[local_featurename][remote_featurename]["rule"] = d.first[2]
      end
    end
    
    @result.delinquents.map{|d|[d.scraping_rule.local_featurename, d.scraping_rule.remote_featurename, d.scraping_rule, d.product_id, d.parsed, d.raw]}.group_by{|d|d[0]}.each_pair do |local_featurename,d|
      d.group_by{|d|d[1]}.each_pair do |remote_featurename, d|
        @delinquent_rules[local_featurename][remote_featurename]["products"] = d.map{|dd|[dd[3],dd[4],dd[5]]}
        @delinquent_rules[local_featurename][remote_featurename]["rule"] = d.first[2]
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
          if (parsed.blank? && !raw.blank?) || (parsed == "**LOW") || (parsed == "**HIGH")
            #This is a missing value
            which_class = Delinquent
            errors += 1
          else # Rule processed fine. This is a candidate for product creation stage
            which_class = Candidate
          end
          which_class.create(:parsed => parsed, :raw => raw, :scraping_rule_id => ii["rule"].id, :product_id => sku, :result_id => @result.id)
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
end
