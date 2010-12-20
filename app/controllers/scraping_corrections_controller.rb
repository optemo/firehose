class ScrapingCorrectionsController < ApplicationController
  # GET /scraping_corrections
  # GET /scraping_corrections.xml
  def index
    @scraping_corrections = ScrapingCorrection.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @scraping_corrections }
    end
  end

  # GET /scraping_corrections/1
  # GET /scraping_corrections/1.xml
  def show
    @scraping_correction = ScrapingCorrection.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @scraping_correction }
    end
  end

  # GET /scraping_corrections/new
  # GET /scraping_corrections/new.xml
  def new
    @scraping_correction = ScrapingCorrection.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @scraping_correction }
    end
  end

  # GET /scraping_corrections/1/edit
  def edit
    @scraping_correction = ScrapingCorrection.find(params[:id])
  end

  # POST /scraping_corrections
  # POST /scraping_corrections.xml
  def create
    @scraping_correction = ScrapingCorrection.new(params[:scraping_correction])

    respond_to do |format|
      if @scraping_correction.save
        format.html { render :text => "You have successfully created a correction" }
        format.xml  { render :xml => @scraping_correction, :status => :created, :location => @scraping_correction }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @scraping_correction.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /scraping_corrections/1
  # PUT /scraping_corrections/1.xml
  def update
    @scraping_correction = ScrapingCorrection.find(params[:id])

    respond_to do |format|
      if @scraping_correction.update_attributes(params[:scraping_correction])
        format.html { redirect_to(@scraping_correction, :notice => 'Scraping correction was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @scraping_correction.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /scraping_corrections/1
  # DELETE /scraping_corrections/1.xml
  def destroy
    @scraping_correction = ScrapingCorrection.find(params[:id])
    @scraping_correction.destroy

    respond_to do |format|
      format.html { redirect_to(scraping_corrections_url) }
      format.xml  { head :ok }
    end
  end
end
