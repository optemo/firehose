class ResultsController < ApplicationController
  # GET /results
  # GET /results.xml
  def index
    @results = Result.order('id DESC')
    @changes = params.include?(:changes)

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
    @rules, @multirules, @colors = Candidate.organize(@result.candidates)
    if (newcount = @rules.values.first.values.first.first.count) < @product_count
      @warning = "#{@product_count-newcount} product#{'s' if @product_count-newcount > 1} missing"
      @exists_count = @product_count
      @product_count = newcount
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @result }
    end
  end

  # GET /results/new
  # GET /results/new.xml
  def new
    @result = Result.new(:product_type => Session.current.product_type, :category => Session.category_id)

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
    @result.scraping_rules = ScrapingRule.find_all_by_product_type_and_active(Session.current.product_type, true)
    raise ValidationError unless @result.category
    product_skus = BestBuyApi.category_ids(@result.category)
    @result.nonuniq = product_skus.count
    product_skus.uniq!
    @result.total = product_skus.count
    @result.save
    
    # Make sure each rule knows which results it is part of
    ScrapingRule.find_all_by_active(true).each {|r| r.results.push(@result); r.save}
    candidate_records = ScrapingRule.scrape(product_skus).each{|c|c.result_id = @result.id}
    Candidate.transaction do
      candidate_records.each(&:save)
    end
    
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
