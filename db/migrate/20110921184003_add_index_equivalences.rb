class AddIndexEquivalences < ActiveRecord::Migration
  def self.up
    add_index :equivalences, :product_id
    add_index :equivalences, :eq_id
  end

  def self.down
    remove_index :equivalences, :product_id
    remove_index :equivalences, :eq_id
  end
end
