module ApplicationHelper
  
  def change_retailer_in_url(retailer)
    cur_url = request.fullpath.split('/')
    cur_url[1] = retailer + 'Departments'
    new_url = cur_url.join('/')
    return new_url
  end
end
