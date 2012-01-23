class ChangeStyleInFacets < ActiveRecord::Migration
  def up
    Facet.where("used_for = 'sortby' AND name = 'saleprice_factor_high'").update_all(:style => "asc", :name => "saleprice_factor")
  end

  def down
    Facet.where("used_for = 'sortby' AND name = 'saleprice_factor' AND style = 'asc'").update_all(:style => "", :name => 'saleprice_factor_high')
  end
end
