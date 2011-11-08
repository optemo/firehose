class CreateDailySpecs < ActiveRecord::Migration
  def self.up
    create_table :daily_specs do |t|
      t.primary_key :id
      t.string :sku
      t.string :name
      t.string :spec_type
      t.string :value_txt
      t.float :value_flt
      t.boolean :value_bin
      t.string :product_type
      t.date :date

      t.timestamps
    end
  end

  def self.down
    drop_table :daily_specs
  end
end
