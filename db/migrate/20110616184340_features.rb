class Features < ActiveRecord::Migration
  def self.up
    create_table :features do |t|
      t.references :heading, :null => false
      t.string :name, :null => false
      t.string :feature_type, {:null => false, :default => 'Categorical'}
      t.string :used_for, :default => 'show'
      t.string :used_for_categories
      t.integer :used_for_order, :default => 9999
      t.boolean :larger_is_better, :default => true
      t.integer :min, :default => 0
      t.integer :max, :default => 0
      t.integer :utility_weight, :default => 1
      t.integer :cluster_weight, :default => 1
      t.string :prefered
      t.timestamps
    end

    add_index :features, [:heading_id, :name], :unique => true     

  end


  def self.down
    remove_index :features, [:heading_id, :name]
    drop_table :features
  end
end
