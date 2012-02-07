class ChangeProductType < ActiveRecord::Migration

    def up
      add_column :daily_specs, :product_type_id, :integer
      change_type_in(DailySpec)
      remove_column :daily_specs, :product_type
      add_column :bin_specs, :product_type_id, :integer
      change_type_in(BinSpec)
      remove_column :bin_specs, :product_type    
      add_column :cat_specs, :product_type_id, :integer
      change_type_in(CatSpec)
      remove_column :cat_specs, :product_type
      add_column :cont_specs, :product_type_id, :integer
      change_type_in(ContSpec)
      remove_column :cont_specs, :product_type
      add_column :text_specs, :product_type_id, :integer
      change_type_in(TextSpec)
      remove_column :text_specs, :product_type
    end
  
    def down
      add_column :daily_specs, :product_type, :string
      change_type_in(DailySpec)
      remove_column :daily_specs, :product_type_id  
      add_column :bin_specs, :product_type, :string
      change_type_in(BinSpec)
      remove_column :bin_specs, :product_type_id
      add_column :cat_specs, :product_type, :string
      change_type_in(CatSpec)
      remove_column :cat_specs, :product_type_id
      add_column :cont_specs, :product_type, :string
      change_type_in(ContSpec)
      remove_column :cont_specs, :product_type_id
      add_column :text_specs, :product_type, :string
      change_type_in(TextSpec)
      remove_column :text_specs, :product_type_id
    end
  
  def change_type_in(m)
    m.where("product_type = 'camera_bestbuy'").update_all(:product_type_id => 2)
    m.where("product_type = 'tv_bestbuy'").update_all(:product_type_id => 4)
    m.where("product_type = 'drive_bestbuy'").update_all(:product_type_id => 6)
  end
  
  def change_type_back(m)
    m.where("product_type_id = 2").update_all(:product_type => 'camera_bestbuy')
    m.where("product_type_id = 4").update_all(:product_type => 'tv_bestbuy')
    m.where("product_type_id = 6").update_all(:product_type => 'drive_bestbuy')
  end
end
