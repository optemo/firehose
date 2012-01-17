class ChangeStyleInFacets < ActiveRecord::Migration
  def up
    Facet.where("used_for = 'sortby' AND name = 'saleprice_factor_high'").update_all(:style => "asc", :name => "saleprice_factor")
    #Facet.update_all(:updates => , :conditions => "used_for = 'sortby'")
    # style column only when sortby: by default 'desc'; for all those that don't have it, add 'desc', else
    # leave as is
  end

  def down
    Facet.where("used_for = 'sortby' AND name = 'saleprice_factor' AND style = 'asc'").update_all(:style => "", :name => 'saleprice_factor_high')
  end
end
