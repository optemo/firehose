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
    
    Session.category_id = YAML.load(@result.category)
    @product_count = @result.total
    @rules, @multirules, @colors = Candidate.organize(@result.candidates)

    if (newcount = @rules.values.first.first.count) < @product_count
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
    @result = Result.new(:product_type => Session.product_type, :category => Session.category_id.to_yaml)

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
    @result.create_from_current
    
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
    Result.find(params[:id]).destroy
   
    respond_to do |format|
      format.html { head :ok}
      format.xml  { head :ok }
    end

  end
  
  # POST /reults/commit/1
  # POST /results/commit/1.xml
  def commit
    @result = Result.find(params[:id])
    Product.create_from_result(@result.id)
    redirect_to '/results'
  end
end
