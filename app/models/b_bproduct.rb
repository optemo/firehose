class BBproduct
  attr_accessor :id, :category
  def initialize(params = {})
    @id = params[:id]
    @category = params [:category]
  end
end