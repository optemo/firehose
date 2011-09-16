class CreateEquivalences < ActiveRecord::Migration
  def self.up
    create_table :equivalences do |t|
      t.integer :product_id
      t.integer :eq_id
    end
  end

  def self.down
    drop_table :equivalences
  end
end
