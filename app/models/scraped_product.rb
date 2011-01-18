class ScrapedProduct
  attr_accessor :id, :parsed, :raw, :corrected, :rule, :delinquent, :scraping_correction_id
  
  def initialize(params)
    @id = params[:id]
    @parsed = params[:parsed]
    @raw = params[:raw]
    @corrected = params[:corrected]
    @rule = params[:rule]
    @delinquent = params[:delinquent]
    @scraping_correction_id = params[:scraping_correction_id]
  end
end