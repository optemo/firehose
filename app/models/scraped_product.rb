class ScrapedProduct
  attr_accessor :id, :parsed, :raw, :corrected
  
  def initialize(params)
    @id = params[:id]
    @parsed = params[:parsed]
    @raw = params[:raw]
    @corrected = params[:corrected]
  end
end