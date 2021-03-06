class ChangeProductType < ActiveRecord::Migration

    def up
      #_specs table
      remove_column :bin_specs, :product_type
      remove_column :cat_specs, :product_type
      remove_column :cont_specs, :product_type
      remove_column :text_specs, :product_type

      #Products table
      give_product_new_types #Leaf nodes
      remove_column :products, :product_type
      remove_column :products, :title
      remove_column :products, :model
      remove_column :products, :mpn
      remove_column :products, :created_at
      remove_column :products, :updated_at
      
      #Facets
      add_column :facets, :product_type, :string
      convert_type_id(Facet) #Tree Nodes
      remove_column :facets, :product_type_id

      #Product Variations
      remove_column :product_bundles, :product_type
      remove_column :product_siblings, :product_type

      #Scraping
      remove_column :scraping_corrections, :product_type
      convert_type(ScrapingRule) #Leaf nodes
      remove_column :scraping_rules, :active

      #Search
      remove_column :searches, :groupby
      remove_column :searches, :searchpids
      remove_column :searches, :searchterm
      remove_column :searches, :session_id
      add_column :searches, :product_type, :string #Will get tree nodes
      
      #Remove old tables
      drop_table :candidates
      drop_table :features
      drop_table :headings
      drop_table :results
      drop_table :urls
      drop_table :surveys
      drop_table :search_products
      drop_table :category_id_product_type_maps
      drop_table :product_types
    end
  
    def down
      #_specs table
      add_column :bin_specs, :product_type, :string
      add_column :cat_specs, :product_type, :string
      add_column :cont_specs, :product_type, :string
      add_column :text_specs, :product_type, :string

      #Products table
      add_column :products, :product_type, :string
      add_column :products, :title, :string
      add_column :products, :model, :string
      add_column :products, :mpn, :string
      
      #Facets
      add_column :facets, :product_type_id, :integer
      remove_column :facets, :product_type

      #Product Variations
      add_column :product_bundles, :product_type, :string
      add_column :product_siblings, :product_type, :string

      #Scraping
      add_column :scraping_corrections, :product_type, :string
      add_column :scraping_rules, :active, :boolean

      #Search
      add_column :searches, :groupby, :string
      add_column :searches, :searchpids, :string
      add_column :searches, :searchterm, :string
      add_column :searches, :session_id, :integer
      remove_column :searches, :product_type
    end
  
  def give_product_new_types
    Product.all.each do |p|
      new_type = type_to_str(p.product_type)
      CatSpec.create name: 'product_type', value: new_type, product_id: p.id
    end
  end
  
  def convert_type_id(model)
    model.all.each do |p|
      p.update_attribute(:product_type, type_id_to_str(p.product_type_id))
    end
  end
  
  def convert_type(model)
    model.all.each do |p|
      p.update_attribute(:product_type, type_to_str(p.product_type))
    end
  end
  
  def type_to_str(type)
    case type
      when 'camera_bestbuy' then 'B20218'
      when 'drive_bestbuy' then 'B20232'
      when 'dslr_bestbuy' then 'B29157'
      when 'laptop_bestbuy' then 'B20352'
      when 'camera_futureshop' then 'F1127'
      when 'dslr_futureshop' then 'F23773'
      #when 'lens_flash_filter_futureshop' then 'F25855'    #uncomment when required by FS
      #Note: have scraping rules for instant_camera_futureshop and digital_photo_frame_futureshop if necessary
      when 'laptop_futureshop' then 'F1002'
      when 'hard_drive_futureshop' then 'F1084'
      when 'usb_drive_futureshop' then ' F23813'
      when 'optical_drive_futureshop' then 'F1082'
      when 'disc_and_case_futureshop' then 'F23033'
      else 'B00000'
    end
  end
  
  def type_id_to_str(type_id)
    pt = ProductType.find_by_id(type_id)
    if pt.nil?
      nil
    else
      type_to_str(pt.name)
    end
  end
end
