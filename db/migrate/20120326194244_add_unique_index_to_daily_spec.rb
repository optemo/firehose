class AddUniqueIndexToDailySpec < ActiveRecord::Migration
  def change
    add_index(:daily_specs, [:sku,:name,:product_type,:date], {:unique => true})
  end
end
