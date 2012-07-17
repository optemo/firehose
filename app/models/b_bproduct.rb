# In the update task, BBproduct lists are serialized to YAML, so that they can be passed
# to child processes for scraping. Adding additional fields to BBproduct will increase
# the time to create the temporary files containing the BBproduct lists.
class BBproduct
  attr_accessor :id, :category
  def initialize(params = {})
    @id = params[:id]
    @category = params[:category]
  end
end
